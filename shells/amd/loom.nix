# Developer shell for ROCm Loom and the HRX System (HIP Runtime Extended)
# Inherits PyTorch 2.12 and Flash Attention 2 capabilities from standard-dev,
# but deliberately omits XRT/pyxrt (as Loom/HRX operates over libamdf and direct Linux DRM).
#
# Supported Workflows:
# 1. Method A: Drop-in HIP runtime replacement for PyTorch/ROCm apps (hrx-run python app.py)
# 2. Method B: Native HRX Heterogeneous C/C++ API (<hrx_runtime.h>, libhrx.so, hrxcc, hrxcxx)
# 3. Method C: ROCm Loom compiler & unified GPU/NPU dispatch (loom-compile, iree-run-loom, iree-xdna-run)
{ lib, ... }:

let
  commonRocmModule = import ./common.nix { inherit lib; };
  mkCommonRocm = commonRocmModule.flake.lib.mkCommonRocm;

  # Function to generate Loom & HRX devShells for any target architecture and ROCm version without hardcoding
  mkLoomDevShells =
    {
      pkgs,
      gfx ? throw "mkLoomDevShells: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'gfx1201', 'gfx942').",
      version ? "10.1.0",
      rocmPkg ? pkgs.callPackage ../../pkgs/rocm-therock { inherit gfx version; },
      loomPkg ? pkgs.callPackage ../../pkgs/hrx-loom { },
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
          torchVersion
          tritonVersion
          ;
      };

      scripts = import ./scripts.nix { inherit lib pkgs; };
      hrxRun = scripts.mkHrxRun;
      hrxCc = scripts.mkHrxCc;
      hrxCxx = scripts.mkHrxCxx;
      buildHrxSystem = scripts.mkBuildHrxSystem { inherit rocmPkg gfx; };
    in
    let
      # Minimal HRX / Loom Runtime Shell
      loom = pkgs.mkShell {
        name = "rocm-loom-${gfx}";
        packages = [
          rocmPkg
          hrxRun
          hrxCc
          hrxCxx
          pkgs.pciutils
          pkgs.libdrm
        ];
        env = {
          ROCM_PATH = "${rocmPkg}";
          HIP_PATH = "${rocmPkg}";
          AMDGPU_TARGETS = gfx;
          GPU_TARGETS = gfx;
          HSA_OVERRIDE_GFX_VERSION = if gfx == "gfx1151" then "11.5.1" else null;
        };
        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${
            lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              rocmPkg
              pkgs.libdrm
            ]
          }:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:$PATH"

          # Discover or configure HRX & Loom runtime directory
          export HRX_DIR="''${HRX_DIR:-$HOME/.local/share/rocm/hrx-system}"
          if [ ! -d "$HRX_DIR" ] && [ -d "/tmp/hrx-system/install" ]; then
            export HRX_DIR="/tmp/hrx-system/install"
          fi

          if [ -d "$HRX_DIR" ]; then
            export PATH="$HRX_DIR/bin:$PATH"
            export LD_LIBRARY_PATH="$HRX_DIR/lib64:$HRX_DIR/lib:$LD_LIBRARY_PATH"
            export LIBRARY_PATH="$HRX_DIR/lib64:$HRX_DIR/lib:$LIBRARY_PATH"
            export C_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$C_INCLUDE_PATH"
            export CPLUS_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$CPLUS_INCLUDE_PATH"
            export CMAKE_PREFIX_PATH="$HRX_DIR/lib64/cmake/hrx:$HRX_DIR/lib64/cmake/loomc:$CMAKE_PREFIX_PATH"
            export HRX_HIP_PRELOAD="$HRX_DIR/lib64/libamdhip64.so"
          fi

          # Session toggle helpers
          enable-hrx-hip() {
            if [ ! -f "$HRX_HIP_PRELOAD" ]; then
              echo "Error: HRX libamdhip64.so not found at $HRX_HIP_PRELOAD"
              return 1
            fi
            export LD_PRELOAD="$HRX_HIP_PRELOAD"
            echo "✓ HRX HIP runtime enabled globally for this session"
            echo "  Active: $LD_PRELOAD"
          }

          disable-hrx-hip() {
            unset LD_PRELOAD
            echo "✓ Restored standard ROCm HIP runtime"
          }

          export -f enable-hrx-hip disable-hrx-hip

          echo "=========================================================="
          echo "  ROCm HRX Runtime Environment (${gfx})"
          echo "  ROCM_PATH:       ${rocmPkg}"
          echo "  HRX Runtime Dir: $HRX_DIR"
          echo "  Commands:        hrx-run <exec>   (run app with HRX)"
          echo "                   enable-hrx-hip   (enable HRX globally)"
          echo "                   disable-hrx-hip  (restore ROCm HIP)"
          echo "=========================================================="
        '';
      };

      # Flagship Loom & HRX Development Shell (with PyTorch + FA2 + Compilers)
      loom-dev = pkgs.mkShell {
        name = "rocm-loom-dev-${gfx}";
        packages = common.commonPackages ++ [
          # Declarative Loom SDK v0.1.0 (loom-compile, loom-serve, libloomc, libiree)
          loomPkg
          # HRX runtime wrappers & optional source builder
          hrxRun
          hrxCc
          hrxCxx
          buildHrxSystem
          # Bazel
          pkgs.bazelisk
          pkgs.bazel_7
          # Rust toolchain
          pkgs.rustc
          pkgs.cargo
          pkgs.clippy
          pkgs.rustfmt
          pkgs.rust-analyzer
        ];

        env = common.commonEnv // {
          IREE_ROCM_PATH = "${rocmPkg}";
          RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
        };

        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${loomPkg}/lib:${common.commonLdLibraryPath}:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:${loomPkg}/bin:$PATH"

          # Auto-activate shared ROCm virtual environment (with PyTorch and Flash Attention 2)
          ${common.venvActivationHook}

          # Link declarative Loom SDK into active venv site-packages
          if [ -n "''${VIRTUAL_ENV:-}" ]; then
            VENV_SITE="$("$VIRTUAL_ENV/bin/python" -c "import site; print(site.getsitepackages()[0])" 2>/dev/null || true)"
            if [ -n "$VENV_SITE" ] && [ -d "$VENV_SITE" ] && [ ! -f "$VENV_SITE/loom.pth" ]; then
              echo "${loomPkg}/lib/python3.14/site-packages" > "$VENV_SITE/loom.pth"
            fi
          fi

          # Discover or configure HRX & Loom runtime directory
          export HRX_DIR="''${HRX_DIR:-$HOME/.local/share/rocm/hrx-system}"
          if [ ! -d "$HRX_DIR" ] && [ -d "/tmp/hrx-system/install" ]; then
            export HRX_DIR="/tmp/hrx-system/install"
          fi

          if [ -d "$HRX_DIR" ]; then
            export PATH="$HRX_DIR/bin:$PATH"
            export LD_LIBRARY_PATH="$HRX_DIR/lib64:$HRX_DIR/lib:$LD_LIBRARY_PATH"
            export LIBRARY_PATH="$HRX_DIR/lib64:$HRX_DIR/lib:$LIBRARY_PATH"
            export C_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$C_INCLUDE_PATH"
            export CPLUS_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$CPLUS_INCLUDE_PATH"
            export CMAKE_PREFIX_PATH="$HRX_DIR/lib64/cmake/hrx:$HRX_DIR/lib64/cmake/loomc:$CMAKE_PREFIX_PATH"
            export HRX_HIP_PRELOAD="$HRX_DIR/lib64/libamdhip64.so"
          fi

          # Session toggle helpers
          enable-hrx-hip() {
            if [ ! -f "$HRX_HIP_PRELOAD" ]; then
              echo "Error: HRX libamdhip64.so not found at $HRX_HIP_PRELOAD"
              return 1
            fi
            export LD_PRELOAD="$HRX_HIP_PRELOAD"
            echo "✓ HRX HIP runtime enabled globally for this session"
            echo "  Active: $LD_PRELOAD"
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
          echo "  ROCm Loom & HRX System Studio (Unified PyTorch + Flash Attention + Loom)"
          echo "================================================================================"
          echo "  AMDGPU Target:   ${if gfx == "gfx1151" then "Radeon 8060S (gfx1151)" else gfx}"
          if [ -e /dev/accel/accel0 ]; then
            echo "  XDNA NPU Target: AIE2p (amd.xdna.strix_halo.17f0_11 over /dev/accel/accel0)"
            echo "  NPU Transport:   Direct Linux DRM (libamdf - Zero XRT)"
          fi
          echo "  PyTorch Stack:   ${torchVersion} (Active Venv: ''${VIRTUAL_ENV:-None})"
          echo "  HRX Runtime Dir: $HRX_DIR"
          echo ""
          echo "  Supported Execution Workflows:"
          echo "  ------------------------------------------------------------------------------"
          echo "  1. Method A: Run PyTorch / ROCm Apps with HRX Runtime:"
          echo "     $ hrx-run python my_script.py        # Intercepts HIP with HRX libamdhip64"
          echo "     $ enable-hrx-hip                     # Toggles HRX for entire session"
          echo ""
          echo "  2. Method B: Native HRX Heterogeneous C/C++ API (<hrx_runtime.h>):"
          echo "     $ hrxcc my_app.c -o my_app           # Compiles with -lhrx and rpath"
          echo "     $ hrxcxx my_app.cpp -o my_app        # Compiles with C++ HRX helpers"
          echo ""
          echo "  3. Method C: ROCm Loom DSL & Hardware Compilation:"
          echo "     $ loom-compile input.loom -target amdgpu:${gfx} -o out.hsaco"
          echo "     $ loom-compile input.loom -target amd.xdna.aie2p:... -o out.xdna"
          echo "     $ iree-xdna-run out.xdna             # Dispatches directly to NPU"
          echo "     $ amdf-enumerate                     # Discovers active GPU/NPU bus"
          echo "     $ hrx-info                           # Displays HRX accelerator endpoints"
          echo "================================================================================"
        '';
      };
    in
    {
      inherit loom loom-dev;
    };
in
{
  flake.lib.mkLoomDevShells = mkLoomDevShells;
  flake.lib.mkLoomDevShell = args: (mkLoomDevShells args).loom-dev;

  perSystem =
    { pkgs, ... }:
    let
      # Default devshells for lunar-qualia (native Strix Halo gfx1151)
      shellsGfx1151 = mkLoomDevShells {
        inherit pkgs;
        gfx = "gfx1151";
      };
    in
    {
      devShells = {
        loom-dev = shellsGfx1151.loom-dev;
        "loom-dev-gfx1151" = shellsGfx1151.loom-dev;

        loom = shellsGfx1151.loom;
        "loom-gfx1151" = shellsGfx1151.loom;
      };
    };
}
