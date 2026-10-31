{ self, ... }:

{
  perSystem = { pkgs, ... }: {
    packages = {
      mem-ttm = pkgs.callPackage ./mem-ttm { };
      amdgpu-boost = pkgs.callPackage ./amdgpu-boost { };
      sync-power-state = pkgs.callPackage ./sync-power-state { };
      service-deck-helper = pkgs.callPackage ./service-deck-helper { };
      plasma-widget-servicedeck = pkgs.callPackage ./plasma-widget-servicedeck { };
      plasma-widget-amdgpuboost = pkgs.callPackage ./plasma-widget-amdgpuboost { };
      app = pkgs.callPackage ./app { };
      xrt-amdxdna = pkgs.callPackage ./xrt-amdxdna { };
      triellama = pkgs.callPackage ./triellama { };
      beellama = pkgs.callPackage ./triellama { };
      radeon-developer-tool-suite = pkgs.callPackage ./radeon-developer-tool-suite { };
      rgp = pkgs.callPackage ./radeon-developer-tool-suite { };
      hrx-loom = pkgs.callPackage ./hrx-loom { };
      loom = pkgs.callPackage ./hrx-loom { };
    };
  };

  flake.overlays.default = final: prev: {
    mem-ttm = final.callPackage ./mem-ttm { };
    amd-ttm = final.mem-ttm;
    amdgpu-boost = final.callPackage ./amdgpu-boost { };
    sync-power-state = final.callPackage ./sync-power-state { };
    service-deck-helper = final.callPackage ./service-deck-helper { };
    plasma-widget-servicedeck = final.callPackage ./plasma-widget-servicedeck { };
    plasma-widget-amdgpuboost = final.callPackage ./plasma-widget-amdgpuboost { };
    app = final.callPackage ./app { };
    rocm-therock = final.callPackage ./rocm-therock;
    xrt-amdxdna = final.callPackage ./xrt-amdxdna { };
    triellama = final.callPackage ./triellama { };
    beellama = final.triellama;
    radeon-developer-tool-suite = final.callPackage ./radeon-developer-tool-suite { };
    rdts = final.radeon-developer-tool-suite;
    rgp = final.radeon-developer-tool-suite;
    radeon-gpu-profiler = final.radeon-developer-tool-suite;
    hrx-loom = final.callPackage ./hrx-loom { };
    loom = final.hrx-loom;

    # Upstream nixpkgs unstable bumped mcp to 2.x where fastmcp-slim is marked broken.
    # Override fastmcp-slim with nixpkgs's backwards-compatible mcp_1 (1.29.0).
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (pyFinal: pyPrev: {
        fastmcp-slim = pyPrev.fastmcp-slim.override {
          mcp = pyFinal.mcp_1;
        };
      })
    ];
  };
}
