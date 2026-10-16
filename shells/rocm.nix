# Unified developer shell for AMD ROCm (TheRock), HIP, PyTorch AI, Flash Attention, and XDNA (NPU)
{ lib, ... }:

let
  # Function to generate devShells for any target architecture and ROCm version without hardcoding
  mkRocmDevShells =
    {
      pkgs,
      gfx ? throw "mkRocmDevShells: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'multiarch').",
      version ? "10.1.0",
      rocmPkg ? pkgs.callPackage ../pkgs/rocm-therock { inherit gfx version; },
      xrtPkg ? pkgs.callPackage ../pkgs/xrt-amdxdna { },
      torchVersion ? "2.12.0+rocm${rocmPkg.version}",
      tritonVersion ? "3.8.0+git669b31ac.rocm${rocmPkg.version}",
    }:
    let
      # Immutable constraints file preventing third-party packages from pulling PyPI CPU/CUDA builds
      constraintsFile = pkgs.writeText "rocm-torch-constraints-${gfx}.txt" ''
        torch==${torchVersion}
        triton==${tritonVersion}
        amd-torch-device-${gfx}==${torchVersion}
      '';

      # Build script for Flash Attention 2 with AITER Triton/CK backend
      buildFlashAttnScript = pkgs.writeShellScriptBin "build-flash-attention" ''
        set -euo pipefail
        if [ -z "''${VIRTUAL_ENV:-}" ]; then
          GLOBAL_DEFAULT="''${XDG_DATA_HOME:-$HOME/.local/share}/rocm/venv-${gfx}"
          if [ -d "$GLOBAL_DEFAULT" ]; then
            source "$GLOBAL_DEFAULT/bin/activate"
          else
            echo "Error: No active virtual environment found. Run 'init-rocm-venv' first."
            exit 1
          fi
        fi
        echo "==> Building Flash Attention 2 for active environment: $VIRTUAL_ENV"
        echo "==> Cloning Flash Attention (shallow)..."
        TMPDIR=$(mktemp -d)
        trap 'rm -rf "$TMPDIR"' EXIT
        git clone --depth 1 https://github.com/Dao-AILab/flash-attention "$TMPDIR/flash-attention"
        (
          cd "$TMPDIR/flash-attention"
          git submodule update --init --depth 1 third_party/aiter csrc/composable_kernel || true
          echo "==> Building & installing aiter..."
          AITER_USE_SYSTEM_TRITON=1 ENABLE_CK=1 PREBUILD_KERNELS=0 \
            pip install --no-build-isolation --no-deps ./third_party/aiter
          echo "==> Building & installing flash-attention..."
          FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE" \
            pip install --no-build-isolation --no-deps .
        )
        echo "==> Flash Attention 2 successfully built and installed!"
      '';

      # Bootstrap script for a locked, clean virtual environment with ROCm PyTorch & optional IRON NPU tools
      initVenvScript = pkgs.writeShellScriptBin "init-rocm-venv" ''
        set -euo pipefail
        WITH_FLASH_ATTN=0
        WITH_IRON=0
        TARGET_DIR=""

        for arg in "$@"; do
          case "$arg" in
            --flash-attn|--with-flash-attn)
              WITH_FLASH_ATTN=1
              ;;
            --iron|--with-iron)
              WITH_IRON=1
              ;;
            -h|--help)
              echo "Usage: init-rocm-venv [directory] [--flash-attn] [--with-iron]"
              echo "  directory     Target directory (defaults to ~/.local/share/rocm/venv-${gfx})"
              echo "  --flash-attn  Automatically build and install Flash Attention 2"
              echo "  --with-iron   Automatically install MLIR-AIE (IRON) & Peano LLVM compiler wheels"
              exit 0
              ;;
            *)
              if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$arg"
              fi
              ;;
          esac
        done

        GLOBAL_DEFAULT="''${XDG_DATA_HOME:-$HOME/.local/share}/rocm/venv-${gfx}"
        VENV_DIR="''${TARGET_DIR:-$GLOBAL_DEFAULT}"

        mkdir -p "$(dirname "$VENV_DIR")"
        if [ ! -d "$VENV_DIR" ]; then
          echo "==> Creating virtual environment at $VENV_DIR..."
          ${pkgs.python3}/bin/python3 -m venv "$VENV_DIR"
        fi
        source "$VENV_DIR/bin/activate"

        # Link host pyxrt from xrt-amdxdna package into venv site-packages
        SITE_PKGS="$("$VENV_DIR/bin/python" -c "import site; print(site.getsitepackages()[0])")"
        echo "${xrtPkg}/lib/python3.14/site-packages" > "$SITE_PKGS/xrt.pth"

        echo "==> Installing ROCm ${rocmPkg.version} PyTorch & ${gfx} device libraries..."
        uv pip install --extra-index-url https://stable.repo.amd.com/rocm/whl-next \
          "torch==${torchVersion}" \
          "triton==${tritonVersion}" \
          "amd-torch-device-${gfx}==${torchVersion}" \
          pip setuptools wheel ninja packaging psutil einops pybind11 numpy pandas flydsl pyyaml

        if [ "$WITH_FLASH_ATTN" -eq 1 ]; then
          echo "==> Building Flash Attention 2 (--flash-attn requested)..."
          ${buildFlashAttnScript}/bin/build-flash-attention
        fi

        if [ "$WITH_IRON" -eq 1 ]; then
          echo "==> Installing MLIR-AIE (IRON) & Peano LLVM compiler wheels for Ryzen AI NPU..."
          uv pip install mlir_aie --find-links https://github.com/Xilinx/mlir-aie/releases/expanded_assets/v1.4.2
          uv pip install llvm-aie --find-links https://github.com/Xilinx/llvm-aie/releases/expanded_assets/nightly-20240501-20260527
          echo "==> Configuring Peano compiler environment..."
          PEANO_DIR="$VENV_DIR/lib/python3.14/site-packages/llvm-aie"
          if [ -d "$PEANO_DIR" ]; then
            echo "export PEANO_INSTALL_DIR=\"$PEANO_DIR\"" >> "$VENV_DIR/bin/activate"
            echo "export AIECC_PATH=\"$VENV_DIR/bin/aiecc\"" >> "$VENV_DIR/bin/activate"
            echo "export AIE_XCLBINUTIL=\"${xrtPkg}/bin/xclbinutil\"" >> "$VENV_DIR/bin/activate"
          fi
        fi

        echo "==> Ready! Virtual environment at $VENV_DIR is active and protected from CPU package drift."
      '';

      # Standalone helper script to bootstrap IRON NPU tools into active or default venv
      initIronScript = pkgs.writeShellScriptBin "init-iron-venv" ''
        set -euo pipefail
        ${initVenvScript}/bin/init-rocm-venv "''${1:-}" --with-iron
      '';
    in
    {
      # Variant 1: Minimal HIP Runtime (Diagnostics & device execution)
      hip-runtime = pkgs.mkShell {
        name = "rocm-hip-runtime-${gfx}";
        packages = [
          rocmPkg
          pkgs.pciutils
        ];
        env = {
          ROCM_PATH = "${rocmPkg}";
          HIP_PATH = "${rocmPkg}";
          HSA_OVERRIDE_GFX_VERSION = if gfx == "gfx1151" then "11.5.1" else null;
        };
        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${
            lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              rocmPkg
            ]
          }:$LD_LIBRARY_PATH"
          echo "=========================================================="
          echo "  ROCm ${rocmPkg.version} (TheRock) - HIP Runtime (${gfx})"
          echo "  ROCM_PATH: ${rocmPkg}"
          echo "=========================================================="
          ${rocmPkg}/bin/rocminfo | grep -E 'Name:[[:space:]]+gfx' || true
        '';
      };

      # Variant 2: Flagship Unified AI Development Shell (ROCm GPU + XDNA NPU + Rust Toolchain)
      amd-ai-dev = pkgs.mkShell {
        name = "amd-ai-dev-${gfx}";
        packages = [
          rocmPkg
          xrtPkg
          pkgs.cargo
          pkgs.rustc
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
          pkgs.git
          pkgs.gcc
          pkgs.gnumake
          pkgs.ccache
          pkgs.sccache
          pkgs.python3
          pkgs.python3Packages.pip
          pkgs.python3Packages.virtualenv
          pkgs.uv
          pkgs.zlib
          pkgs.openssl
          pkgs.libdrm
          pkgs.numactl
          pkgs.elfutils
          pkgs.pciutils
          pkgs.util-linux
          initVenvScript
          initIronScript
          buildFlashAttnScript
        ];
        env = {
          ROCM_PATH = "${rocmPkg}";
          HIP_PATH = "${rocmPkg}";
          XILINX_XRT = "${xrtPkg}";
          AIE_XCLBINUTIL = "${xrtPkg}/bin/xclbinutil";
          HIP_PLATFORM = "amd";
          HIP_COMPILER = "clang";
          HIP_CLANG_PATH = "${rocmPkg}/lib/llvm/bin";
          CMAKE_PREFIX_PATH = "${rocmPkg}:${rocmPkg}/lib/cmake:${xrtPkg}:${xrtPkg}/share/cmake";

          # Compiler caching integration
          CMAKE_C_COMPILER_LAUNCHER = "ccache";
          CMAKE_CXX_COMPILER_LAUNCHER = "ccache";

          # AMD shader / kernel compilation caches
          AMD_COMGR_CACHE_ENABLE = "1";
          ROCFFT_KERNEL_CACHE_ENABLE = "1";
          HSA_OVERRIDE_GFX_VERSION = if gfx == "gfx1151" then "11.5.1" else null;
          PYTORCH_ROCM_ARCH = gfx;
          AMDGPU_TARGETS = gfx;
          GPU_TARGETS = gfx;

          # Flash Attention 2 & AITER build/runtime flags
          FLASH_ATTENTION_TRITON_AMD_ENABLE = "TRUE";
          AITER_USE_SYSTEM_TRITON = "1";
          ENABLE_CK = "1";
          PREBUILD_KERNELS = "0";

          # Package management constraints & wheel indexes
          PIP_EXTRA_INDEX_URL = "https://stable.repo.amd.com/rocm/whl-next";
          UV_EXTRA_INDEX_URL = "https://stable.repo.amd.com/rocm/whl-next";
          PIP_CONSTRAINT = "${constraintsFile}";
          UV_CONSTRAINT = "${constraintsFile}";
        };
        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${xrtPkg}/lib:${
            lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              rocmPkg
              xrtPkg
              pkgs.zlib
              pkgs.openssl
              pkgs.libdrm
              pkgs.numactl
              pkgs.elfutils
              pkgs.util-linux.lib
            ]
          }:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:${xrtPkg}/bin:$PATH"

          GLOBAL_VENV="''${XDG_DATA_HOME:-$HOME/.local/share}/rocm/venv-${gfx}"

          if [ -d ".venv" ] && [ -z "''${VIRTUAL_ENV:-}" ]; then
            echo "==> Activating project-local virtual environment (./.venv)..."
            source .venv/bin/activate
          elif [ -d "$GLOBAL_VENV" ] && [ -z "''${VIRTUAL_ENV:-}" ]; then
            echo "==> Activating shared ROCm virtual environment ($GLOBAL_VENV)..."
            source "$GLOBAL_VENV/bin/activate"
          elif [ -z "''${VIRTUAL_ENV:-}" ]; then
            echo "==> First-time setup: Auto-bootstrapping shared ROCm environment at $GLOBAL_VENV..."
            ${initVenvScript}/bin/init-rocm-venv "$GLOBAL_VENV"
            source "$GLOBAL_VENV/bin/activate"
          fi

          # Auto-configure Peano compiler if present in active venv
          if [ -n "''${VIRTUAL_ENV:-}" ] && [ -d "$VIRTUAL_ENV/lib/python3.14/site-packages/llvm-aie" ]; then
            export PEANO_INSTALL_DIR="$VIRTUAL_ENV/lib/python3.14/site-packages/llvm-aie"
            export AIECC_PATH="$VIRTUAL_ENV/bin/aiecc"
          fi

          echo "=========================================================="
          echo "  AMD Unified AI Development Environment (${gfx} + XDNA)"
          echo "  ROCm (TheRock):   ${rocmPkg.version} (at ${rocmPkg})"
          echo "  Compiler:         $(${rocmPkg}/bin/hipcc --version | head -n 1)"
          echo "  Rust Toolchain:   $(cargo --version)"
          echo "  Build Cache:      ccache & sccache (CMake launcher: ccache)"
          echo "  Locked PyTorch:   ${torchVersion}"
          echo "  Active Venv:      ''${VIRTUAL_ENV:-None}"
          if [ -e /dev/accel/accel0 ]; then
            echo "  NPU Device:       /dev/accel/accel0 (XRT ${xrtPkg.version} ready)"
          fi
          echo "  Commands:         build-flash-attention   (compile Flash Attention 2)"
          echo "                    init-rocm-venv [dir] [--flash-attn] [--with-iron]"
          echo "                    init-iron-venv [dir]   (install MLIR-AIE IRON wheels)"
          echo "                    xrt-smi examine        (NPU status & telemetry)"
          echo "=========================================================="
        '';
      };
    };
in
{
  flake.lib.mkRocmDevShells = mkRocmDevShells;

  perSystem =
    { pkgs, ... }:
    let
      # Default devshells for lunar-qualia (native Strix Halo gfx1151)
      shellsGfx1151 = mkRocmDevShells {
        inherit pkgs;
        gfx = "gfx1151";
      };
    in
    {
      devShells = {
        # Primary unified devShell
        amd-ai-dev = shellsGfx1151.amd-ai-dev;
        "amd-ai-dev-gfx1151" = shellsGfx1151.amd-ai-dev;

        # Backward compatibility aliases
        torch-dev = shellsGfx1151.amd-ai-dev;
        hip-dev = shellsGfx1151.amd-ai-dev;
        "torch-dev-gfx1151" = shellsGfx1151.amd-ai-dev;
        "hip-dev-gfx1151" = shellsGfx1151.amd-ai-dev;

        # Minimal runtime shell
        hip-runtime = shellsGfx1151.hip-runtime;
        "hip-runtime-gfx1151" = shellsGfx1151.hip-runtime;
      };
    };
}
