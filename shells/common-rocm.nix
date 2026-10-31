# Shared foundation for AMD ROCm development shells (TheRock, Loom, HRX)
{ lib, ... }:

let
  mkCommonRocm =
    {
      pkgs,
      gfx ? throw "mkCommonRocm: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'gfx1201', 'gfx942').",
      version ? "10.1.0",
      rocmPkg ? pkgs.callPackage ../pkgs/rocm-therock { inherit gfx version; },
      torchVersion ? "2.12.0+rocm${rocmPkg.version}",
      tritonVersion ? "3.8.0+git669b31ac.rocm${rocmPkg.version}",
      xrtPkg ? null,
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

      # Unified bootstrap script for locked ROCm PyTorch virtual environment
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
              echo "Usage: init-rocm-venv [directory] [--flash-attn]${
                lib.optionalString (xrtPkg != null) " [--with-iron]"
              }"
              echo "  directory     Target directory (defaults to ~/.local/share/rocm/venv-${gfx})"
              echo "  --flash-attn  Automatically build and install Flash Attention 2"
              ${lib.optionalString (xrtPkg != null) ''
                echo "  --with-iron   Automatically install MLIR-AIE (IRON) & Peano LLVM compiler wheels"
              ''}
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

        ${lib.optionalString (xrtPkg != null) ''
          # Link host pyxrt from xrt-amdxdna package into venv site-packages
          SITE_PKGS="$("$VENV_DIR/bin/python" -c "import site; print(site.getsitepackages()[0])")"
          echo "${xrtPkg}/lib/python3.14/site-packages" > "$SITE_PKGS/xrt.pth"
        ''}

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

        ${lib.optionalString (xrtPkg != null) ''
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
        ''}

        echo "==> Ready! Virtual environment at $VENV_DIR is active."
      '';

      commonPackages = [
        rocmPkg
        buildFlashAttnScript
        initVenvScript
        pkgs.cmake
        pkgs.ninja
        pkgs.pkg-config
        pkgs.git
        pkgs.gcc
        pkgs.gnumake
        pkgs.clang
        pkgs.lld
        pkgs.ccache
        pkgs.sccache
        pkgs.python3
        pkgs.python3Packages.pip
        pkgs.python3Packages.virtualenv
        pkgs.uv
        pkgs.python3Packages.pyyaml
        pkgs.ruff
        pkgs.zlib
        pkgs.openssl
        pkgs.pciutils
        pkgs.libdrm
        pkgs.numactl
        pkgs.elfutils
        pkgs.util-linux
      ];

      commonEnv = {
        ROCM_PATH = "${rocmPkg}";
        HIP_PATH = "${rocmPkg}";
        AMDGPU_TARGETS = gfx;
        GPU_TARGETS = gfx;
        PYTORCH_ROCM_ARCH = gfx;
        HSA_OVERRIDE_GFX_VERSION = if gfx == "gfx1151" then "11.5.1" else null;
        HIP_PLATFORM = "amd";
        HIP_COMPILER = "clang";
        HIP_CLANG_PATH = "${rocmPkg}/lib/llvm/bin";

        # Compiler caching
        CMAKE_C_COMPILER_LAUNCHER = "ccache";
        CMAKE_CXX_COMPILER_LAUNCHER = "ccache";
        AMD_COMGR_CACHE_ENABLE = "1";
        ROCFFT_KERNEL_CACHE_ENABLE = "1";

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

      commonLdLibraryPath = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        rocmPkg
        pkgs.zlib
        pkgs.openssl
        pkgs.libdrm
        pkgs.numactl
        pkgs.elfutils
        pkgs.util-linux.lib
      ];

      venvActivationHook = ''
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
      '';
    in
    {
      inherit
        constraintsFile
        buildFlashAttnScript
        initVenvScript
        commonPackages
        commonEnv
        commonLdLibraryPath
        venvActivationHook
        rocmPkg
        torchVersion
        tritonVersion
        ;
    };
in
{
  flake.lib.mkCommonRocm = mkCommonRocm;
}
