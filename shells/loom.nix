# Developer shell for ROCm Loom and the HRX System (HIP Runtime Extended)
{ lib, ... }:

{
  perSystem =
    { pkgs, ... }:
    let
      # Use Strix Halo rocm-therock package for device headers and runtime libraries
      rocmPkg = pkgs.callPackage ../pkgs/rocm-therock { gfx = "gfx1151"; };
    in
    {
      devShells.loom-dev = pkgs.mkShell {
        name = "rocm-loom-dev";
        packages = [
          rocmPkg
          pkgs.bazelisk
          pkgs.bazel_7
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
          pkgs.git
          pkgs.gcc
          pkgs.gnumake
          pkgs.clang
          pkgs.lld
          pkgs.python312
          pkgs.uv
          pkgs.python312Packages.pyyaml
          pkgs.ruff
          pkgs.pciutils
          pkgs.libdrm
          pkgs.numactl
          pkgs.elfutils
        ];

        env = {
          ROCM_PATH = "${rocmPkg}";
          IREE_ROCM_PATH = "${rocmPkg}";
          AMDGPU_TARGETS = "gfx1151";
          GPU_TARGETS = "gfx1151";
          HSA_OVERRIDE_GFX_VERSION = "11.5.1";
        };

        shellHook = ''
          export LD_LIBRARY_PATH="${rocmPkg}/lib:${rocmPkg}/lib/llvm/lib:${rocmPkg}/lib/rocm_sysdeps/lib:${lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.libdrm pkgs.numactl ]}:$LD_LIBRARY_PATH"
          export PATH="${rocmPkg}/bin:${rocmPkg}/lib/llvm/bin:$PATH"

          echo "=========================================================="
          echo "  ROCm Loom & HRX System Development Studio"
          echo "  Repository:       https://github.com/ROCm/hrx-system"
          echo "  Build System:     Bazelisk / Bazel 7 & CMake/Ninja"
          echo "  AMDGPU Target:    Radeon 8060S (gfx1151)"
          if [ -e /dev/accel/accel0 ]; then
            echo "  XDNA NPU Target:  amd.xdna.aie2p:amd.xdna.strix_halo.17f0_11"
            echo "  Transport:        libamdf over Linux DRM (/dev/accel/accel0)"
          fi
          echo "  Quickstart:       python dev.py bazel setup"
          echo "                    python dev.py bazel precommit"
          echo "=========================================================="
        '';
      };
    };
}
