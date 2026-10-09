# Flake developer shells aggregator
{ ... }:

{
  imports = [
    ./rocm.nix
  ];

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
}
