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

  # Unified PyTorch, Attention (Flash Attention + AITER), and NPU (IRON) virtual environment bootstrapper
  mkInitVenvScript =
    {
      gfx,
      rocmPkg,
      torchVersion,
      tritonVersion,
      xrtPkg ? null,
      loomPkg ? null,
    }:
    pkgs.writeShellScriptBin "init-venv" ''
      set -euo pipefail

      WANT_TORCH=0
      WANT_ATTN=0
      WANT_IRON=0
      FORCE_FRESH=0
      TARGET_DIR=""
      FLAGS_GIVEN=0

      for arg in "$@"; do
        case "$arg" in
          --torch)
            WANT_TORCH=1
            FLAGS_GIVEN=1
            ;;
          -fa|--flash-attn|--flash-attention)
            WANT_ATTN=1
            FLAGS_GIVEN=1
            ;;
          --iron)
            WANT_IRON=1
            FLAGS_GIVEN=1
            ;;
          --fresh|--no-cache)
            FORCE_FRESH=1
            ;;
          -h|--help)
            echo "Usage: init-venv [directory] [options]"
            echo ""
            echo "Initializes a ROCm Python virtual environment with copyable/cached packages."
            echo ""
            echo "Tier Selection (defaults to all if none specified):"
            echo "  --torch                          Install PyTorch, Triton & ROCm device libraries"
            echo "  -fa, --flash-attn, --flash-attention"
            echo "                                   Install Flash Attention 2 + AITER & Composable Kernel"
            echo "  --iron                           Install Ryzen AI NPU MLIR-AIE (IRON) & Peano LLVM compiler"
            echo ""
            echo "Options:"
            echo "  directory                        Target directory (defaults to ./.venv)"
            echo "  --fresh, --no-cache              Force a fresh build/download instead of reflink copy"
            exit 0
            ;;
          *)
            if [ -z "$TARGET_DIR" ]; then
              TARGET_DIR="$arg"
            fi
            ;;
        esac
      done

      # Default: if no specific tier flags were passed, install everything
      if [ "$FLAGS_GIVEN" -eq 0 ]; then
        WANT_TORCH=1
        WANT_ATTN=1
        WANT_IRON=1
      fi

      # Attention & IRON both depend on PyTorch
      if [ "$WANT_ATTN" -eq 1 ] || [ "$WANT_IRON" -eq 1 ]; then
        WANT_TORCH=1
      fi

      VENV_DIR="''${TARGET_DIR:-./.venv}"
      PKG_CACHE="''${XDG_DATA_HOME:-$HOME/.local/share}/rocm/pkg-cache-${gfx}"
      WHEELS_CACHE="''${XDG_DATA_HOME:-$HOME/.local/share}/rocm/wheels-${gfx}"

      mkdir -p "$VENV_DIR"
      if [ ! -f "$VENV_DIR/bin/python" ]; then
        echo "==> Creating virtual environment at $VENV_DIR..."
        ${pkgs.python3}/bin/python3 -m venv "$VENV_DIR"
      fi

      # Activate the target environment
      source "$VENV_DIR/bin/activate"
      SITE_PKGS="$("$VENV_DIR/bin/python" -c "import site; print(site.getsitepackages()[0])")"

      ${lib.optionalString (loomPkg != null) ''
        # Link declarative Loom SDK
        echo "${loomPkg}/lib/python3.14/site-packages" > "$SITE_PKGS/loom.pth"
      ''}

      ${lib.optionalString (xrtPkg != null) ''
        # Link host pyxrt for XDNA NPU
        echo "${xrtPkg}/lib/python3.14/site-packages" > "$SITE_PKGS/xrt.pth"
      ''}

      # --------------------------------------------------------------------------
      # Fast Reflink Copy from Package Cache
      # --------------------------------------------------------------------------
      if [ "$FORCE_FRESH" -eq 0 ] && [ -d "$PKG_CACHE" ] && [ "$(ls -A "$PKG_CACHE" 2>/dev/null)" ]; then
        echo "==> Seeding packages from cache via Btrfs reflink ($PKG_CACHE -> $SITE_PKGS)..."
        cp -a --reflink=auto "$PKG_CACHE"/* "$SITE_PKGS/" 2>/dev/null || true
      fi

      # --------------------------------------------------------------------------
      # Tier 1: PyTorch (ROCm backend, Triton, device libraries)
      # --------------------------------------------------------------------------
      if [ "$WANT_TORCH" -eq 1 ]; then
        if ! "$VENV_DIR/bin/python" -c "import torch" >/dev/null 2>&1; then
          echo "==> Installing ROCm ${rocmPkg.version} PyTorch & ${gfx} device libraries..."
          uv pip install --extra-index-url https://stable.repo.amd.com/rocm/whl-next \
            "torch==${torchVersion}" \
            "triton==${tritonVersion}" \
            "amd-torch-device-${gfx}==${torchVersion}" \
            pip setuptools wheel ninja packaging psutil einops pybind11 numpy pandas flydsl pyyaml
        else
          echo "✓ PyTorch stack available in environment"
        fi
      fi

      # --------------------------------------------------------------------------
      # Tier 2: Flash Attention 2 (with AITER & Composable Kernel)
      # --------------------------------------------------------------------------
      if [ "$WANT_ATTN" -eq 1 ]; then
        if ! "$VENV_DIR/bin/python" -c "import flash_attn, aiter" >/dev/null 2>&1; then
          mkdir -p "$WHEELS_CACHE"
          if ls "$WHEELS_CACHE"/flash_attn*.whl >/dev/null 2>&1 && ls "$WHEELS_CACHE"/aiter*.whl >/dev/null 2>&1; then
            echo "==> Installing Flash Attention 2 & AITER from wheel cache..."
            uv pip install --find-links "$WHEELS_CACHE" --no-deps flash_attn aiter
          else
            echo "==> Building Flash Attention 2 & AITER wheels from Dao-AILab repository..."
            TMPDIR=$(mktemp -d)
            trap 'rm -rf "$TMPDIR"' EXIT
            git clone --depth 1 https://github.com/Dao-AILab/flash-attention "$TMPDIR/flash-attention"
            (
              cd "$TMPDIR/flash-attention"
              git submodule update --init --depth 1 third_party/aiter csrc/composable_kernel || true
              echo "==> Packaging AITER wheel..."
              AITER_USE_SYSTEM_TRITON=1 ENABLE_CK=1 PREBUILD_KERNELS=0 \
                pip wheel --no-build-isolation --no-deps -w "$WHEELS_CACHE" ./third_party/aiter
              echo "==> Packaging Flash Attention 2 wheel..."
              FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE" \
                pip wheel --no-build-isolation --no-deps -w "$WHEELS_CACHE" .
            )
            uv pip install --find-links "$WHEELS_CACHE" --no-deps flash_attn aiter
          fi
        else
          echo "✓ Flash Attention 2 & AITER available in environment"
        fi
      fi

      # --------------------------------------------------------------------------
      # Tier 3: IRON (MLIR-AIE + Peano LLVM compiler for Ryzen AI NPU)
      # --------------------------------------------------------------------------
      if [ "$WANT_IRON" -eq 1 ]; then
        ${lib.optionalString (xrtPkg != null) ''
          if ! "$VENV_DIR/bin/python" -c "import aie" >/dev/null 2>&1; then
            echo "==> Installing MLIR-AIE (IRON) & Peano LLVM compiler wheels for Ryzen AI NPU..."
            uv pip install mlir_aie --find-links https://github.com/Xilinx/mlir-aie/releases/expanded_assets/v1.4.2
            uv pip install llvm-aie --find-links https://github.com/Xilinx/llvm-aie/releases/expanded_assets/nightly-20240501-20260527
          else
            echo "✓ MLIR-AIE (IRON) available in environment"
          fi

          PEANO_DIR="$VENV_DIR/lib/python3.14/site-packages/llvm-aie"
          if [ -d "$PEANO_DIR" ]; then
            if ! grep -q "PEANO_INSTALL_DIR" "$VENV_DIR/bin/activate"; then
              echo "export PEANO_INSTALL_DIR=\"$PEANO_DIR\"" >> "$VENV_DIR/bin/activate"
              echo "export AIECC_PATH=\"$VENV_DIR/bin/aiecc\"" >> "$VENV_DIR/bin/activate"
              echo "export AIE_XCLBINUTIL=\"${xrtPkg}/bin/xclbinutil\"" >> "$VENV_DIR/bin/activate"
            fi
          fi
        ''}
      fi

      # --------------------------------------------------------------------------
      # Sync Installed Packages back to Cache
      # --------------------------------------------------------------------------
      mkdir -p "$PKG_CACHE"
      cp -a --reflink=auto "$SITE_PKGS"/* "$PKG_CACHE/" 2>/dev/null || true

      echo "================================================================================"
      echo "✓ Virtual environment initialized and active at: $VENV_DIR"
      echo "  Python:  $("$VENV_DIR/bin/python" --version)"
      echo "  Tiers:   $([ "$WANT_TORCH" -eq 1 ] && echo -n "PyTorch ")$([ "$WANT_ATTN" -eq 1 ] && echo -n "Flash-Attn/AITER ")$([ "$WANT_IRON" -eq 1 ] && echo -n "IRON")"
      echo "================================================================================"
    '';

  # HRX Method 1: Drop-in HIP runtime wrapper
  mkHrxRun =
    { hrxRuntimePkg }:
    pkgs.writeShellScriptBin "hrx-run" ''
      HRX_DIR="''${HRX_DIR:-${hrxRuntimePkg}}"
      if [ -f "$HRX_DIR/lib/libamdhip64.so" ]; then
        LIBDIR="$HRX_DIR/lib"
      elif [ -f "$HRX_DIR/lib64/libamdhip64.so" ]; then
        LIBDIR="$HRX_DIR/lib64"
      else
        LIBDIR="$HRX_DIR"
      fi

      if [ $# -eq 0 ]; then
        echo "Usage: hrx-run <executable> [args...]"
        echo "Executes any standard ROCm/HIP application with HRX's lightweight runtime preloaded."
        exit 1
      fi

      if [ ! -f "$LIBDIR/libamdhip64.so" ]; then
        echo "Error: HRX libamdhip64.so not found at $LIBDIR/libamdhip64.so"
        exit 1
      fi

      LD_PRELOAD="$LIBDIR/libamdhip64.so" exec "$@"
    '';

  # HRX Method 2: C compiler wrapper
  mkHrxCc =
    { hrxRuntimePkg }:
    pkgs.writeShellScriptBin "hrxcc" ''
      HRX_DIR="''${HRX_DIR:-${hrxRuntimePkg}}"
      exec clang -I"$HRX_DIR/include" -I"$HRX_DIR/include/hrx" -L"$HRX_DIR/lib" -lhrx -Wl,-rpath,"$HRX_DIR/lib" "$@"
    '';

  # HRX Method 2: C++ compiler wrapper
  mkHrxCxx =
    { hrxRuntimePkg }:
    pkgs.writeShellScriptBin "hrxcxx" ''
      HRX_DIR="''${HRX_DIR:-${hrxRuntimePkg}}"
      exec clang++ -I"$HRX_DIR/include" -I"$HRX_DIR/include/hrx" -L"$HRX_DIR/lib" -lhrx -Wl,-rpath,"$HRX_DIR/lib" "$@"
    '';
}
