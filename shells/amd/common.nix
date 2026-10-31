# Shared foundation for AMD ROCm development shells (TheRock, Loom, HRX)
{ lib, ... }:

let
  mkCommonRocm =
    {
      pkgs,
      gfx ? throw "mkCommonRocm: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'gfx1201', 'gfx942').",
      version ? "10.1.0",
      rocmPkg ? pkgs.callPackage ../../pkgs/rocm-therock { inherit gfx version; },
      torchVersion ? "2.12.0+rocm${rocmPkg.version}",
      tritonVersion ? "3.8.0+git669b31ac.rocm${rocmPkg.version}",
      xrtPkg ? null,
    }:
    let
      scripts = import ./scripts.nix { inherit lib pkgs; };

      constraintsFile = scripts.mkConstraintsFile {
        inherit gfx torchVersion tritonVersion;
      };

      buildFlashAttnScript = scripts.mkBuildFlashAttnScript {
        inherit gfx;
      };

      initVenvScript = scripts.mkInitVenvScript {
        inherit
          gfx
          rocmPkg
          torchVersion
          tritonVersion
          xrtPkg
          buildFlashAttnScript
          ;
      };

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
