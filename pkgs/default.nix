{ self, ... }:

let
  inTreePackages = {
    mem-ttm = ./mem-ttm;
    sync-power-state = ./sync-power-state;
    service-deck-helper = ./service-deck-helper;
    plasma-widget-servicedeck = ./plasma-widget-servicedeck;
    xrt-amdxdna = ./xrt-amdxdna;
    triellama = ./triellama;
    radeon-developer-tool-suite = ./radeon-developer-tool-suite;
    hrx-loom = ./hrx-loom;
    hrx-runtime = ./hrx-runtime;
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages = (builtins.mapAttrs (_name: path: pkgs.callPackage path { }) inTreePackages) // {
        rocm-therock-gfx1151 = pkgs.callPackage ./rocm-therock { gfx = "gfx1151"; };
      };
    };

  flake.overlays.default =
    final: prev:
    (builtins.mapAttrs (_name: path: final.callPackage path { }) inTreePackages)
    // {
      rocm-therock = final.callPackage ./rocm-therock;
      rocm-therock-gfx1151 = final.callPackage ./rocm-therock { gfx = "gfx1151"; };

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
