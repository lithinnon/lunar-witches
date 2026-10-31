# Unified developer shell for AMD ROCm (TheRock), HIP, PyTorch AI, Flash Attention, and XDNA (NPU)
{ lib, ... }:

let
  commonRocmModule = import ./common-rocm.nix { inherit lib; };
  mkCommonRocm = commonRocmModule.flake.lib.mkCommonRocm;

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

      # Standalone helper script to bootstrap IRON NPU tools into active or default venv
      initIronScript = pkgs.writeShellScriptBin "init-iron-venv" ''
        set -euo pipefail
        ${common.initVenvScript}/bin/init-rocm-venv "''${1:-}" --with-iron
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
        packages = common.commonPackages ++ [
          xrtPkg
          pkgs.cargo
          pkgs.rustc
          initIronScript
        ];
        env = common.commonEnv // {
          XILINX_XRT = "${xrtPkg}";
          AIE_XCLBINUTIL = "${xrtPkg}/bin/xclbinutil";
          CMAKE_PREFIX_PATH = "${rocmPkg}:${rocmPkg}/lib/cmake:${xrtPkg}:${xrtPkg}/share/cmake";
        };
        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${xrtPkg}/lib:${common.commonLdLibraryPath}:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:${xrtPkg}/bin:$PATH"

          ${common.venvActivationHook}

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
