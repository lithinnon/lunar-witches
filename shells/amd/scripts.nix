# Reusable shell scripts and runtime helpers for AMD devShells
{ lib, pkgs }:

rec {
  # Constraints file pinning PyTorch/Triton/Device versions
  mkConstraintsFile =
    {
      gfx,
      torchVersion,
      tritonVersion,
    }:
    pkgs.writeText "rocm-torch-constraints-${gfx}.txt" ''
      torch==${torchVersion}
      triton==${tritonVersion}
      amd-torch-device-${gfx}==${torchVersion}
    '';

  # Flash Attention 2 + AITER Triton/CK builder
  mkBuildFlashAttnScript =
    { gfx }:
    pkgs.writeShellScriptBin "build-flash-attention" ''
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

  # Unified PyTorch & device library virtual environment bootstrapper
  mkInitVenvScript =
    {
      gfx,
      rocmPkg,
      torchVersion,
      tritonVersion,
      xrtPkg ? null,
      buildFlashAttnScript,
    }:
    pkgs.writeShellScriptBin "init-rocm-venv" ''
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

  # Helper to bootstrap IRON NPU tools into active or default venv
  mkInitIronScript =
    { initVenvScript }:
    pkgs.writeShellScriptBin "init-iron-venv" ''
      set -euo pipefail
      ${initVenvScript}/bin/init-rocm-venv "''${1:-}" --with-iron
    '';

  # HRX Method 1: Drop-in HIP runtime wrapper
  mkHrxRun = pkgs.writeShellScriptBin "hrx-run" ''
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

  # HRX Method 2: C compiler wrapper
  mkHrxCc = pkgs.writeShellScriptBin "hrxcc" ''
    HRX_DIR="''${HRX_DIR:-$HOME/.local/share/rocm/hrx-system}"
    if [ ! -d "$HRX_DIR/include" ] && [ -d "/tmp/hrx-system/install/include" ]; then
      HRX_DIR="/tmp/hrx-system/install"
    fi
    exec clang -I"$HRX_DIR/include" -I"$HRX_DIR/include/hrx" -L"$HRX_DIR/lib64" -lhrx -Wl,-rpath,"$HRX_DIR/lib64" "$@"
  '';

  # HRX Method 2: C++ compiler wrapper
  mkHrxCxx = pkgs.writeShellScriptBin "hrxcxx" ''
    HRX_DIR="''${HRX_DIR:-$HOME/.local/share/rocm/hrx-system}"
    if [ ! -d "$HRX_DIR/include" ] && [ -d "/tmp/hrx-system/install/include" ]; then
      HRX_DIR="/tmp/hrx-system/install"
    fi
    exec clang++ -I"$HRX_DIR/include" -I"$HRX_DIR/include/hrx" -L"$HRX_DIR/lib64" -lhrx -Wl,-rpath,"$HRX_DIR/lib64" "$@"
  '';

  # HRX Source Build Automation Helper
  mkBuildHrxSystem =
    { rocmPkg, gfx }:
    pkgs.writeShellScriptBin "build-hrx-system" ''
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
}
