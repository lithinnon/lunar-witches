# Features and services aggregator
{ ... }:

{
  imports = [
    ./syncthing.nix
    ./chulawifi.nix
    ./openssh.nix
    ./sops.nix
  ];
}
