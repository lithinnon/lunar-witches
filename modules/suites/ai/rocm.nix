# Capability suite: ROCm 10.1 (TheRock) AI & Compute Optimization Environment
{ self, lib, ... }:

let
  # Function to generate devShells for any target architecture without defaults
  mkRocmDevShells =
    {
      pkgs,
      targetGfx ? throw "mkRocmDevShells: 'targetGfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'multiarch').",
    }:
    let
      rocmPkg = pkgs.callPackage ../../../pkgs/rocm-therock { inherit targetGfx; };

      # Immutable constraints file preventing third-party packages from pulling PyPI CPU/CUDA builds
      constraintsFile = pkgs.writeText "rocm-torch-constraints-${targetGfx}.txt" ''
        torch==2.12.0+rocm10.1.0
        triton==3.8.0+git669b31ac.rocm10.1.0
        amd-torch-device-${targetGfx}==2.12.0+rocm10.1.0
      '';

      # Bootstrap script for a locked, clean virtual environment with ROCm PyTorch
      initVenvScript = pkgs.writeShellScriptBin "init-rocm-venv" ''
        set -euo pipefail
        VENV_DIR="''${1:-.venv}"
        if [ ! -d "$VENV_DIR" ]; then
          echo "==> Creating virtual environment at $VENV_DIR..."
          ${pkgs.python312}/bin/python3 -m venv "$VENV_DIR"
        fi
        source "$VENV_DIR/bin/activate"
        echo "==> Installing ROCm 10.1 PyTorch & ${targetGfx} device libraries..."
        uv pip install --extra-index-url https://stable.repo.amd.com/rocm/whl-next \
          "torch==2.12.0+rocm10.1.0" \
          "triton==3.8.0+git669b31ac.rocm10.1.0" \
          "amd-torch-device-${targetGfx}==2.12.0+rocm10.1.0" \
          pip setuptools wheel ninja packaging psutil einops pybind11 numpy pandas flydsl
        echo "==> Ready! Virtual environment bootstrapped with zero CPU package drift."
      '';

      # Build script for Flash Attention 2 with AITER Triton/CK backend
      buildFlashAttnScript = pkgs.writeShellScriptBin "build-flash-attention" ''
        set -euo pipefail
        if [ -z "''${VIRTUAL_ENV:-}" ]; then
          echo "Error: No active virtual environment. Run 'init-rocm-venv' first."
          exit 1
        fi
        echo "==> Cloning Flash Attention (shallow)..."
        TMPDIR=$(mktemp -d)
        trap 'rm -rf "$TMPDIR"' EXIT
        git clone --depth 1 https://github.com/Dao-AILab/flash-attention "$TMPDIR/flash-attention"
        (
          cd "$TMPDIR/flash-attention"
          git submodule update --init --depth 1 third_party/aiter 3rdparty/composable_kernel || true
          echo "==> Building & installing aiter..."
          AITER_USE_SYSTEM_TRITON=1 ENABLE_CK=1 PREBUILD_KERNELS=0 \
            pip install --no-build-isolation --no-deps ./third_party/aiter
          echo "==> Building & installing flash-attention..."
          FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE" \
            pip install --no-build-isolation --no-deps .
        )
        echo "==> Flash Attention 2 successfully built and installed!"
      '';
    in
    {
      # Variant 1: HIP Runtime (Minimal diagnostics & execution)
      hip-runtime = pkgs.mkShell {
        name = "rocm-hip-runtime-${targetGfx}";
        packages = [
          rocmPkg
          pkgs.pciutils
        ];
        env = {
          ROCM_PATH = "${rocmPkg}";
          HIP_PATH = "${rocmPkg}";
          HSA_OVERRIDE_GFX_VERSION = if targetGfx == "gfx1151" then "11.5.1" else null;
        };
        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:$LD_LIBRARY_PATH"
          echo "=========================================================="
          echo "  ROCm 10.1 (TheRock) - HIP Runtime (${targetGfx})"
          echo "  ROCM_PATH: ${rocmPkg}"
          echo "=========================================================="
          ${rocmPkg}/bin/rocminfo | grep -E 'Name:[[:space:]]+gfx' || true
        '';
      };

      # Variant 2: HIP Development (C++/HIP compiler, CMake packages, headers)
      hip-dev = pkgs.mkShell {
        name = "rocm-hip-dev-${targetGfx}";
        packages = [
          rocmPkg
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
          pkgs.git
          pkgs.gcc
          pkgs.gnumake
        ];
        env = {
          ROCM_PATH = "${rocmPkg}";
          HIP_PATH = "${rocmPkg}";
          HIP_PLATFORM = "amd";
          HIP_COMPILER = "clang";
          HIP_CLANG_PATH = "${rocmPkg}/lib/llvm/bin";
          CMAKE_PREFIX_PATH = "${rocmPkg}:${rocmPkg}/lib/cmake";
          AMD_COMGR_CACHE_ENABLE = "1";
          ROCFFT_KERNEL_CACHE_ENABLE = "1";
          HSA_OVERRIDE_GFX_VERSION = if targetGfx == "gfx1151" then "11.5.1" else null;
          AMDGPU_TARGETS = targetGfx;
          GPU_TARGETS = targetGfx;
        };
        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:$PATH"
          echo "=========================================================="
          echo "  ROCm 10.1 (TheRock) - HIP Development (${targetGfx})"
          echo "  Compiler: $(${rocmPkg}/bin/hipcc --version | head -n 1)"
          echo "  ROCM_PATH: ${rocmPkg}"
          echo "=========================================================="
        '';
      };

      # Variant 3: PyTorch ROCm Development + Flash Attention (Locked Wheels + Dev Tools)
      torch-dev = pkgs.mkShell {
        name = "rocm-torch-dev-${targetGfx}";
        packages = [
          rocmPkg
          pkgs.python312
          pkgs.python312Packages.pip
          pkgs.python312Packages.virtualenv
          pkgs.uv
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
          pkgs.git
          pkgs.gcc
          pkgs.gnumake
          pkgs.zlib
          pkgs.libdrm
          pkgs.numactl
          initVenvScript
          buildFlashAttnScript
        ];
        env = {
          ROCM_PATH = "${rocmPkg}";
          HIP_PATH = "${rocmPkg}";
          HIP_PLATFORM = "amd";
          HIP_COMPILER = "clang";
          HIP_CLANG_PATH = "${rocmPkg}/lib/llvm/bin";
          CMAKE_PREFIX_PATH = "${rocmPkg}:${rocmPkg}/lib/cmake";
          AMD_COMGR_CACHE_ENABLE = "1";
          ROCFFT_KERNEL_CACHE_ENABLE = "1";
          HSA_OVERRIDE_GFX_VERSION = if targetGfx == "gfx1151" then "11.5.1" else null;
          PYTORCH_ROCM_ARCH = targetGfx;
          AMDGPU_TARGETS = targetGfx;
          GPU_TARGETS = targetGfx;

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
          export LD_LIBRARY_PATH="${rocmPkg}/lib:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:$PATH"
          if [ -d ".venv" ] && [ -z "''${VIRTUAL_ENV:-}" ]; then
            echo "==> Auto-activating existing .venv..."
            source .venv/bin/activate
          fi
          echo "=========================================================="
          echo "  ROCm 10.1 (TheRock) - PyTorch AI Environment (${targetGfx})"
          echo "  ROCM_PATH:        ${rocmPkg}"
          echo "  Locked Index:     https://stable.repo.amd.com/rocm/whl-next"
          echo "  Commands:         init-rocm-venv [dir]   (setup locked venv)"
          echo "                    build-flash-attention  (build Flash Attention 2)"
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
        targetGfx = "gfx1151";
      };
    in
    {
      devShells = {
        hip-runtime = shellsGfx1151.hip-runtime;
        hip-dev = shellsGfx1151.hip-dev;
        torch-dev = shellsGfx1151.torch-dev;

        # Explicit architecture aliases
        "hip-runtime-gfx1151" = shellsGfx1151.hip-runtime;
        "hip-dev-gfx1151" = shellsGfx1151.hip-dev;
        "torch-dev-gfx1151" = shellsGfx1151.torch-dev;
      };
    };

  flake.nixosModules.suite-ai-rocm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.suites.ai.rocm;
      rocmPkg =
        if cfg.targetGfx != null then
          pkgs.callPackage ../../../pkgs/rocm-therock { targetGfx = cfg.targetGfx; }
        else
          null;
    in
    {
      options.suites.ai.rocm = {
        enable = lib.mkEnableOption "ROCm 10.1 (TheRock) AI and GPU compute suite";

        targetGfx = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "gfx1151";
          description = "Target GPU architecture for ROCm (e.g. 'gfx1151', 'gfx1100', 'multiarch'). Must be explicitly specified.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.targetGfx != null;
            message = "suites.ai.rocm.targetGfx must be explicitly set (e.g. 'gfx1151') when suites.ai.rocm is enabled.";
          }
        ];

        environment.systemPackages = lib.optional (rocmPkg != null) rocmPkg;

        programs.nix-ld.libraries = lib.optional (rocmPkg != null) rocmPkg;

        environment.sessionVariables = lib.mkIf (rocmPkg != null) {
          ROCM_PATH = "${rocmPkg}";
          HIP_PATH = "${rocmPkg}";
          CMAKE_PREFIX_PATH = "${rocmPkg}:${rocmPkg}/lib/cmake";
          AMD_COMGR_CACHE_ENABLE = "1";
          ROCFFT_KERNEL_CACHE_ENABLE = "1";
          FLASH_ATTENTION_TRITON_AMD_ENABLE = "TRUE";
        };
      };
    };
}
