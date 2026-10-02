{ self, ... }:

{
  perSystem = { pkgs, ... }: {
    packages = {
      mem-ttm = pkgs.callPackage ./mem-ttm { };
      amdgpu-boost = pkgs.callPackage ./amdgpu-boost { };
      sync-power-state = pkgs.callPackage ./sync-power-state { };
      service-deck-helper = pkgs.callPackage ./service-deck-helper { };
    };
  };

  flake.overlays.default = final: prev: {
    mem-ttm = final.callPackage ./mem-ttm { };
    amd-ttm = final.mem-ttm;
    amdgpu-boost = final.callPackage ./amdgpu-boost { };
    sync-power-state = final.callPackage ./sync-power-state { };
    service-deck-helper = final.callPackage ./service-deck-helper { };
  };
}
