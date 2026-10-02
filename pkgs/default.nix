{ self, ... }:

{
  perSystem = { pkgs, ... }: {
    packages = {
      amd-ttm = pkgs.callPackage ./amd-ttm { };
      amdgpu-boost = pkgs.callPackage ./amdgpu-boost { };
      sync-power-state = pkgs.callPackage ./sync-power-state { };
      service-deck-helper = pkgs.callPackage ./service-deck-helper { };
    };
  };

  flake.overlays.default = final: prev: {
    amd-ttm = final.callPackage ./amd-ttm { };
    amdgpu-boost = final.callPackage ./amdgpu-boost { };
    sync-power-state = final.callPackage ./sync-power-state { };
    service-deck-helper = final.callPackage ./service-deck-helper { };
  };
}
