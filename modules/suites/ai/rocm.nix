# Capability suite: ROCm (TheRock) AI & Compute Optimization Environment
{ self, lib, ... }:

let
  # Function to generate devShells for any target architecture and ROCm version without hardcoding
  mkRocmDevShells =
    {
      pkgs,
      gfx ? throw "mkRocmDevShells: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'multiarch').",
      version ? "10.1.0",
      rocmPkg ? pkgs.callPackage ../../../pkgs/rocm-therock { inherit gfx version; },
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

      # Bootstrap script for a locked, clean virtual environment with ROCm PyTorch
      initVenvScript = pkgs.writeShellScriptBin "init-rocm-venv" ''
        set -euo pipefail
        WITH_FLASH_ATTN=0
        TARGET_DIR=""

        for arg in "$@"; do
          case "$arg" in
            --flash-attn|--with-flash-attn)
              WITH_FLASH_ATTN=1
              ;;
            -h|--help)
              echo "Usage: init-rocm-venv [directory] [--flash-attn]"
              echo "  directory     Target directory (defaults to ~/.local/share/rocm/venv-${gfx})"
              echo "  --flash-attn  Automatically build and install Flash Attention 2"
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
          ${pkgs.python312}/bin/python3 -m venv "$VENV_DIR"
        fi
        source "$VENV_DIR/bin/activate"
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

        echo "==> Ready! Virtual environment at $VENV_DIR is active and protected from CPU package drift."
      '';
    in
    {
      # Variant 1: HIP Runtime (Minimal diagnostics & execution)
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
          export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib rocmPkg ]}:$LD_LIBRARY_PATH"
          echo "=========================================================="
          echo "  ROCm ${rocmPkg.version} (TheRock) - HIP Runtime (${gfx})"
          echo "  ROCM_PATH: ${rocmPkg}"
          echo "=========================================================="
          ${rocmPkg}/bin/rocminfo | grep -E 'Name:[[:space:]]+gfx' || true
        '';
      };

      # Variant 2: HIP Development (C++/HIP compiler, CMake packages, headers)
      hip-dev = pkgs.mkShell {
        name = "rocm-hip-dev-${gfx}";
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
          HSA_OVERRIDE_GFX_VERSION = if gfx == "gfx1151" then "11.5.1" else null;
          AMDGPU_TARGETS = gfx;
          GPU_TARGETS = gfx;
        };
        shellHook = ''
          export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib rocmPkg ]}:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:$PATH"
          echo "=========================================================="
          echo "  ROCm ${rocmPkg.version} (TheRock) - HIP Development (${gfx})"
          echo "  Compiler: $(${rocmPkg}/bin/hipcc --version | head -n 1)"
          echo "  ROCM_PATH: ${rocmPkg}"
          echo "=========================================================="
        '';
      };

      # Variant 3: PyTorch ROCm Development + Flash Attention (Locked Wheels + Dev Tools)
      torch-dev = pkgs.mkShell {
        name = "rocm-torch-dev-${gfx}";
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
          export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib rocmPkg pkgs.zlib pkgs.libdrm pkgs.numactl pkgs.elfutils ]}:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:$PATH"

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

          echo "=========================================================="
          echo "  ROCm ${rocmPkg.version} (TheRock) - PyTorch AI Environment (${gfx})"
          echo "  ROCM_PATH:        ${rocmPkg}"
          echo "  Locked Index:     https://stable.repo.amd.com/rocm/whl-next"
          echo "  Locked PyTorch:   ${torchVersion}"
          echo "  Active Venv:      ''${VIRTUAL_ENV:-None}"
          echo "  Commands:         build-flash-attention   (compile Flash Attention 2)"
          echo "                    init-rocm-venv [dir] [--flash-attn]"
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
        if cfg.gfx != null then
          pkgs.callPackage ../../../pkgs/rocm-therock {
            gfx = cfg.gfx;
            inherit (cfg) version;
          }
        else
          null;
    in
    {
      options.suites.ai.rocm = {
        enable = lib.mkEnableOption "ROCm (TheRock) AI and GPU compute suite";

        gfx = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "gfx1151";
          description = "Target GPU architecture for ROCm (e.g. 'gfx1151', 'gfx1100', 'multiarch'). Must be explicitly specified.";
        };

        version = lib.mkOption {
          type = lib.types.str;
          default = "10.1.0";
          description = "ROCm (TheRock) release version.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.gfx != null;
            message = "suites.ai.rocm.gfx must be explicitly set (e.g. 'gfx1151') when suites.ai.rocm is enabled.";
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
