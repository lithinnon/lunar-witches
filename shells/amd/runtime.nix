# Minimal AMD Hardware Runtime & Diagnostics Shell
# Provides lightweight runtime execution, NPU diagnostics (xrt-smi), and HRX session toggles
# without compiler, Python virtualenv, or build toolchain overhead.
{ lib, ... }:

let
  mkAmdRuntimeShell =
    {
      pkgs,
      gfx ? throw "mkAmdRuntimeShell: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'gfx1201', 'gfx942').",
      version ? "10.1.0",
      rocmPkg ? (pkgs.rocm-therock or (pkgs.callPackage ../../pkgs/rocm-therock)) {
        inherit gfx version;
      },
      xrtPkg ? pkgs.xrt-amdxdna or (pkgs.callPackage ../../pkgs/xrt-amdxdna { }),
      hrxRuntimePkg ? pkgs.hrx-runtime or (pkgs.callPackage ../../pkgs/hrx-runtime { }),
    }:
    let
      scripts = import ./scripts.nix { inherit lib pkgs; };
      hrxRun = scripts.mkHrxRun { inherit hrxRuntimePkg; };
      hrxCc = scripts.mkHrxCc { inherit hrxRuntimePkg; };
      hrxCxx = scripts.mkHrxCxx { inherit hrxRuntimePkg; };
    in
    pkgs.mkShell {
      name = "amd-runtime-${gfx}";
      packages = [
        rocmPkg
        xrtPkg
        hrxRuntimePkg
        hrxRun
        hrxCc
        hrxCxx
        pkgs.pciutils
        pkgs.libdrm
      ];
      env = {
        ROCM_PATH = "${rocmPkg}";
        HIP_PATH = "${rocmPkg}";
        XILINX_XRT = "${xrtPkg}";
        AMDGPU_TARGETS = gfx;
        GPU_TARGETS = gfx;
        HSA_OVERRIDE_GFX_VERSION = if gfx == "gfx1151" then "11.5.1" else null;
      };
      shellHook = ''
        export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${xrtPkg}/lib:${
          lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            rocmPkg
            xrtPkg
            pkgs.libdrm
          ]
        }:$LD_LIBRARY_PATH"
        export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:${xrtPkg}/bin:$PATH"

        # Discover or configure HRX runtime directory
        export HRX_DIR="''${HRX_DIR:-${hrxRuntimePkg}}"

        if [ -d "$HRX_DIR" ]; then
          export PATH="$HRX_DIR/bin:$PATH"
          export LD_LIBRARY_PATH="$HRX_DIR/lib:$HRX_DIR/lib64:$LD_LIBRARY_PATH"
          export LIBRARY_PATH="$HRX_DIR/lib:$HRX_DIR/lib64:$LIBRARY_PATH"
          export C_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$C_INCLUDE_PATH"
          export CPLUS_INCLUDE_PATH="$HRX_DIR/include:$HRX_DIR/include/hrx:$CPLUS_INCLUDE_PATH"
          export CMAKE_PREFIX_PATH="$HRX_DIR/lib/cmake/hrx:$HRX_DIR/lib/cmake/amdf:$CMAKE_PREFIX_PATH"
          if [ -f "$HRX_DIR/lib/libamdhip64.so" ]; then
            export HRX_HIP_PRELOAD="$HRX_DIR/lib/libamdhip64.so"
          else
            export HRX_HIP_PRELOAD="$HRX_DIR/lib64/libamdhip64.so"
          fi
        fi

        # Session toggle helpers
        enable-hrx-hip() {
          if [ -n "''${HRX_HIP_PRELOAD:-}" ] && [ -f "$HRX_HIP_PRELOAD" ]; then
            export LD_PRELOAD="$HRX_HIP_PRELOAD"
            echo "✓ HRX HIP runtime enabled globally for this session"
            echo "  Active: $LD_PRELOAD"
          else
            echo "Error: HRX libamdhip64.so not found at ''${HRX_HIP_PRELOAD:-$HRX_DIR/lib/libamdhip64.so}"
            return 1
          fi
        }

        disable-hrx-hip() {
          unset LD_PRELOAD
          echo "✓ Restored standard ROCm HIP runtime"
        }

        export -f enable-hrx-hip disable-hrx-hip

        echo "=========================================================="
        echo "  AMD Hardware Runtime & Diagnostics (${gfx})"
        echo "  ROCm (TheRock):  ${rocmPkg.version} (at ${rocmPkg})"
        echo "  XRT (NPU):       ${xrtPkg.version} (at ${xrtPkg})"
        echo "  HRX Runtime Dir: $HRX_DIR"
        echo "=========================================================="
        ${rocmPkg}/bin/rocminfo | grep -E 'Name:[[:space:]]+gfx' || true
        if [ -e /dev/accel/accel0 ]; then
          echo "  NPU Device:      /dev/accel/accel0 active"
        fi
      '';
    };
in
{
  flake.lib.mkAmdRuntimeShell = mkAmdRuntimeShell;

  perSystem =
    { pkgs, ... }:
    let
      runtimeGfx1151 = mkAmdRuntimeShell {
        inherit pkgs;
        gfx = "gfx1151";
      };
    in
    {
      devShells = {
        amd-runtime = runtimeGfx1151;
        "amd-runtime-gfx1151" = runtimeGfx1151;
      };
    };
}
