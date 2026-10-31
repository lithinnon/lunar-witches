# Flagship AMD Unified AI & Accelerator Development Shell
# Integrates ROCm (TheRock), PyTorch 2.12, Flash Attention 2, XDNA (NPU via XRT & libamdf),
# Loom SDK v0.1.0, HRX System, and the full Rust/C++ compiler toolchain.
{ lib, ... }:

let
  commonRocmModule = import ./common.nix { inherit lib; };
  mkCommonRocm = commonRocmModule.flake.lib.mkCommonRocm;

  mkAmdDevShell =
    {
      pkgs,
      gfx ? throw "mkAmdDevShell: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'gfx1201', 'gfx942').",
      version ? "10.1.0",
      rocmPkg ? pkgs.callPackage ../../pkgs/rocm-therock { inherit gfx version; },
      xrtPkg ? pkgs.callPackage ../../pkgs/xrt-amdxdna { },
      loomPkg ? pkgs.callPackage ../../pkgs/hrx-loom { },
      hrxRuntimePkg ? pkgs.callPackage ../../pkgs/hrx-runtime { },
      torchVersion ? "2.12.0+rocm${rocmPkg.version}",
      tritonVersion ? "3.8.0+git669b31ac.rocm${rocmPkg.version}",
    }:
    let
      common = mkCommonRocm {
        inherit
          pkgs
          gfx
          version
          rocmPkg
          xrtPkg
          torchVersion
          tritonVersion
          ;
      };

      scripts = import ./scripts.nix { inherit lib pkgs; };
      hrxRun = scripts.mkHrxRun { inherit hrxRuntimePkg; };
      hrxCc = scripts.mkHrxCc { inherit hrxRuntimePkg; };
      hrxCxx = scripts.mkHrxCxx { inherit hrxRuntimePkg; };
    in
    pkgs.mkShell {
      name = "amd-dev-${gfx}";
      packages = common.commonPackages ++ [
        # Silicon & Runtime Packages
        xrtPkg
        loomPkg
        hrxRuntimePkg
        # HRX & Loom runtime wrappers
        hrxRun
        hrxCc
        hrxCxx
        # Rust Toolchain
        pkgs.rustc
        pkgs.cargo
        pkgs.clippy
        pkgs.rustfmt
        pkgs.rust-analyzer
      ];

      env = common.commonEnv // {
        # XRT / NPU Environment
        XILINX_XRT = "${xrtPkg}";
        AIE_XCLBINUTIL = "${xrtPkg}/bin/xclbinutil";
        CMAKE_PREFIX_PATH = "${rocmPkg}:${rocmPkg}/lib/cmake:${xrtPkg}:${xrtPkg}/share/cmake";

        # Loom & Rust Environment
        IREE_ROCM_PATH = "${rocmPkg}";
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
      };

      shellHook = ''
        export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${xrtPkg}/lib:${loomPkg}/lib:${common.commonLdLibraryPath}:$LD_LIBRARY_PATH"
        export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:${xrtPkg}/bin:${loomPkg}/bin:$PATH"

        # Activate project-local ./.venv if present in current directory
        ${common.venvActivationHook}

        # Auto-configure Peano compiler if present in active venv
        if [ -n "''${VIRTUAL_ENV:-}" ] && [ -d "$VIRTUAL_ENV/lib/python3.14/site-packages/llvm-aie" ]; then
          export PEANO_INSTALL_DIR="$VIRTUAL_ENV/lib/python3.14/site-packages/llvm-aie"
          export AIECC_PATH="$VIRTUAL_ENV/bin/aiecc"
        fi

        # Link declarative Loom SDK into active venv site-packages
        if [ -n "''${VIRTUAL_ENV:-}" ]; then
          VENV_SITE="$("$VIRTUAL_ENV/bin/python" -c "import site; print(site.getsitepackages()[0])" 2>/dev/null || true)"
          if [ -n "$VENV_SITE" ] && [ -d "$VENV_SITE" ] && [ ! -f "$VENV_SITE/loom.pth" ]; then
            echo "${loomPkg}/lib/python3.14/site-packages" > "$VENV_SITE/loom.pth"
          fi
        fi

        # Discover or configure HRX runtime directory
        export HRX_DIR="''${HRX_DIR:-${hrxRuntimePkg}}"

        if [ -d "$HRX_DIR" ]; then
          export PATH="$HRX_DIR/bin:$PATH"
          export LD_LIBRARY_PATH="$HRX_DIR/lib:$HRX_DIR/lib64:$LD_LIBRARY_PATH"
          export LIBRARY_PATH="$HRX_DIR/lib:$HRX_DIR/lib64:$LIBRARY_PATH"
          export C_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$C_INCLUDE_PATH"
          export CPLUS_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$CPLUS_INCLUDE_PATH"
          export CMAKE_PREFIX_PATH="$HRX_DIR/lib/cmake/hrx:$HRX_DIR/lib/cmake/amdf:$CMAKE_PREFIX_PATH"
          if [ -f "$HRX_DIR/lib/libamdhip64.so" ]; then
            export HRX_HIP_PRELOAD="$HRX_DIR/lib/libamdhip64.so"
          else
            export HRX_HIP_PRELOAD="$HRX_DIR/lib64/libamdhip64.so"
          fi
        fi

        # Session toggle helpers: Instant switch between standard ROCm and HRX runtime
        enable-hrx-hip() {
          if [ -n "''${HRX_HIP_PRELOAD:-}" ] && [ -f "$HRX_HIP_PRELOAD" ]; then
            export LD_PRELOAD="$HRX_HIP_PRELOAD"
            echo "✓ HRX HIP runtime enabled globally for this session"
            echo "  Active: $LD_PRELOAD"
          else
            echo "Error: HRX libamdhip64.so not found at ''${HRX_HIP_PRELOAD:-$HRX_DIR/lib/libamdhip64.so}"
            return 1
          fi
        }

        disable-hrx-hip() {
          unset LD_PRELOAD
          echo "✓ Restored standard ROCm HIP runtime"
        }

        export -f enable-hrx-hip disable-hrx-hip

        # --------------------------------------------------------------------------
        # Interactive Studio Banner
        # --------------------------------------------------------------------------
        echo "================================================================================"
        echo "  AMD Unified AI Development Studio (${gfx} + XDNA NPU + Loom + HRX)"
        echo "================================================================================"
        echo "  ROCm (TheRock):  ${rocmPkg.version} (Compiler: $(${rocmPkg}/bin/hipcc --version | head -n 1))"
        echo "  Rust Toolchain:  $(cargo --version)"
        echo "  Loom SDK:        ${loomPkg.version}"
        echo "  Locked PyTorch:  ${torchVersion}"
        if [ -e /dev/accel/accel0 ]; then
          echo "  XDNA NPU:        /dev/accel/accel0 (Dual Transports: XRT ${xrtPkg.version} + Direct DRM libamdf)"
        fi
        echo "  Build Cache:     ccache & sccache (CMake launcher: ccache)"
        echo ""
        echo "  Supported Execution Workflows:"
        echo "  ------------------------------------------------------------------------------"
        echo "  1. Python Acceleration & Virtual Environment:"
        echo "     $ init-venv                          # Full stack: PyTorch + Flash-Attn/AITER + IRON"
        echo "     $ init-venv --torch                  # PyTorch 2.12 + Triton only"
        echo "     $ init-venv -fa                      # Flash Attention 2 + AITER"
        echo "     $ init-venv --iron                   # Ryzen AI NPU MLIR-AIE + Peano"
        echo "     $ xrt-smi examine                    # NPU status & telemetry"
        echo ""
        echo "  2. HRX Low-Latency HIP Execution:"
        echo "     $ hrx-run python app.py              # Intercepts HIP with HRX libamdhip64"
        echo "     $ enable-hrx-hip                     # Toggles HRX for entire session"
        echo "     $ disable-hrx-hip                    # Restores standard ROCm HIP"
        echo ""
        echo "  3. Native Heterogeneous C/C++ API:"
        echo "     $ hrxcc app.c -o app                 # Compiles with -lhrx and rpaths"
        echo "     $ hrxcxx app.cpp -o app              # Compiles with C++ HRX helpers"
        echo ""
        echo "  4. ROCm Loom DSL & Hardware Compilation:"
        echo "     $ loom-compile in.loom -target amdgpu:${gfx} -o out.hsaco"
        echo "     $ loom-compile in.loom -target amd.xdna.aie2p:... -o out.xdna"
        echo "================================================================================"
      '';
    };
in
{
  flake.lib.mkAmdDevShell = mkAmdDevShell;

  perSystem =
    { pkgs, ... }:
    let
      devGfx1151 = mkAmdDevShell {
        inherit pkgs;
        gfx = "gfx1151";
      };
    in
    {
      devShells = {
        amd-dev = devGfx1151;
        "amd-dev-gfx1151" = devGfx1151;
      };
    };
}
