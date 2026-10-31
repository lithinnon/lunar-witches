# Developer shell for ROCm Loom and the HRX System (HIP Runtime Extended)
# Inherits PyTorch 2.12 and Flash Attention 2 capabilities from amd-ai-dev,
# but deliberately omits XRT/pyxrt (as Loom/HRX operates over libamdf and direct Linux DRM).
#
# Supported Workflows:
# 1. Method A: Drop-in HIP runtime replacement for PyTorch/ROCm apps (hrx-run python app.py)
# 2. Method B: Native HRX Heterogeneous C/C++ API (<hrx_runtime.h>, libhrx.so, hrxcc, hrxcxx)
# 3. Method C: ROCm Loom compiler & unified GPU/NPU dispatch (loom-compile, iree-run-loom, iree-xdna-run)
{ lib, ... }:

let
  commonRocmModule = import ./common-rocm.nix { inherit lib; };
  mkCommonRocm = commonRocmModule.flake.lib.mkCommonRocm;

  # Function to generate Loom & HRX devShells for any target architecture and ROCm version without hardcoding
  mkLoomDevShells =
    {
      pkgs,
      gfx ? throw "mkLoomDevShells: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'gfx1201', 'gfx942').",
      version ? "10.1.0",
      rocmPkg ? pkgs.callPackage ../pkgs/rocm-therock { inherit gfx version; },
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

      # Method 1 Wrapper: Run any ROCm/HIP application using HRX's lightweight libamdhip64.so
      hrxRun = pkgs.writeShellScriptBin "hrx-run" ''
        HRX_DIR="''${HRX_DIR:-$HOME/.local/share/rocm/hrx-system}"
        if [ ! -f "$HRX_DIR/lib64/libamdhip64.so" ] && [ -f "/tmp/hrx-system/install/lib64/libamdhip64.so" ]; then
          HRX_DIR="/tmp/hrx-system/install"
        fi

        if [ $# -eq 0 ]; then
          echo "Usage: hrx-run <executable> [args...]"
          echo "Executes any standard ROCm/HIP application with HRX's lightweight runtime preloaded."
          exit 1
        fi

        if [ ! -f "$HRX_DIR/lib64/libamdhip64.so" ]; then
          echo "Error: HRX libamdhip64.so not found at $HRX_DIR/lib64/libamdhip64.so"
          echo "Run 'build-hrx-system' to compile the HRX distribution."
          exit 1
        fi

        LD_PRELOAD="$HRX_DIR/lib64/libamdhip64.so" exec "$@"
      '';

      # Method 2 Wrappers: Native HRX C and C++ Compiler Wrappers
      hrxCc = pkgs.writeShellScriptBin "hrxcc" ''
        HRX_DIR="''${HRX_DIR:-$HOME/.local/share/rocm/hrx-system}"
        if [ ! -d "$HRX_DIR/include" ] && [ -d "/tmp/hrx-system/install/include" ]; then
          HRX_DIR="/tmp/hrx-system/install"
        fi
        exec clang -I"$HRX_DIR/include" -I"$HRX_DIR/include/hrx" -L"$HRX_DIR/lib64" -lhrx -Wl,-rpath,"$HRX_DIR/lib64" "$@"
      '';

      hrxCxx = pkgs.writeShellScriptBin "hrxcxx" ''
        HRX_DIR="''${HRX_DIR:-$HOME/.local/share/rocm/hrx-system}"
        if [ ! -d "$HRX_DIR/include" ] && [ -d "/tmp/hrx-system/install/include" ]; then
          HRX_DIR="/tmp/hrx-system/install"
        fi
        exec clang++ -I"$HRX_DIR/include" -I"$HRX_DIR/include/hrx" -L"$HRX_DIR/lib64" -lhrx -Wl,-rpath,"$HRX_DIR/lib64" "$@"
      '';

      # Build Automation Helper
      buildHrxSystem = pkgs.writeShellScriptBin "build-hrx-system" ''
        SRC_DIR="''${1:-$HOME/sources/hrx-system}"
        PREFIX="''${2:-$HOME/.local/share/rocm/hrx-system}"
        echo "Building HRX System & Loom from $SRC_DIR -> $PREFIX..."
        if [ ! -d "$SRC_DIR" ]; then
          mkdir -p "$(dirname "$SRC_DIR")"
          git clone https://github.com/ROCm/hrx-system.git "$SRC_DIR"
        fi
        mkdir -p "$SRC_DIR/build/cmake"
        cmake -S "$SRC_DIR" -B "$SRC_DIR/build/cmake" -GNinja \
          -DIREE_ROCM_PATH="${rocmPkg}" \
          -DIREE_ROCM_DEPENDENCY_MODE=package \
          -DCMAKE_INSTALL_LIBDIR=lib64 \
          -DCMAKE_BUILD_TYPE=Release \
          -DIREE_HAL_DRIVER_AMDGPU=ON \
          -DIREE_HAL_AMDGPU_TARGETS="${gfx}" \
          -DAMDF_BUILD=ON \
          -DAMDF_FAMILY_XDNA=ON
        ninja -C "$SRC_DIR/build/cmake" \
          libhrx_src_binding_hip_amdhip64 \
          libhrx_src_libhrx_hrx \
          libhrx_tools_hrx-info \
          loomc_shared \
          loom-compile \
          iree-run-loom \
          iree-xdna-run \
          enumerate
        cmake --install "$SRC_DIR/build/cmake" --prefix "$PREFIX" --component HrxPublicDist
        cp "$SRC_DIR/build/cmake/loom/src/loom/tools/loom-compile/loom-compile" "$PREFIX/bin/"
        cp "$SRC_DIR/build/cmake/loom/src/loom/tools/iree-run-loom/iree-run-loom" "$PREFIX/bin/"
        cp "$SRC_DIR/build/cmake/experimental/xdna/iree-xdna-run" "$PREFIX/bin/"
        cp "$SRC_DIR/build/cmake/libamdf/examples/enumerate" "$PREFIX/bin/amdf-enumerate"
        cp -d "$SRC_DIR/build/cmake/libamdf"/libamdf.so* "$PREFIX/lib64/"
        ln -sf lib64 "$PREFIX/lib"
        ln -sf hrx/hrx_runtime.h "$PREFIX/include/hrx_runtime.h"
        ln -sf hrx/hrx_runtime_cxx.h "$PREFIX/include/hrx_runtime_cxx.h"
        echo "✓ HRX System built and installed to $PREFIX"
      '';
    in
    {
      # Minimal HRX / Loom Runtime Shell
      loom-runtime = pkgs.mkShell {
        name = "rocm-loom-runtime-${gfx}";
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
          # HRX & Loom runtime wrappers
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
          export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${common.commonLdLibraryPath}:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:$PATH"

          # Auto-activate shared ROCm virtual environment (with PyTorch and Flash Attention 2)
          ${common.venvActivationHook}

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
        # Primary unified Loom devShell
        loom-dev = shellsGfx1151.loom-dev;
        "loom-dev-gfx1151" = shellsGfx1151.loom-dev;

        # Minimal HRX runtime shell
        loom-runtime = shellsGfx1151.loom-runtime;
        "loom-runtime-gfx1151" = shellsGfx1151.loom-runtime;
      };
    };
}
