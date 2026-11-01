# Flake developer shells aggregator
{ lib, ... }:

{
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Flake library functions";
  };

  imports = [
    ./amd
  ];

  config = {
    perSystem =
      { pkgs, ... }:
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixd
            nixfmt-tree
          ];
          shellHook = ''
            if [ -d .githooks ]; then
              git config core.hooksPath .githooks 2>/dev/null || true
            fi
          '';
        };
      };
  };
}
