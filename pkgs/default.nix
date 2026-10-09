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
  };
}
