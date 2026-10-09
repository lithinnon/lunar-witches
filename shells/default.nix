# Flake developer shells aggregator
{ ... }:

{
  imports = [
    ./rocm.nix
    ./loom.nix
  ];

  perSystem =
    { config, ... }:
    {
      devShells.default = config.devShells.amd-ai-dev;
    };
}
