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
            nixfmt
          ];
        };
      };
  };
}
