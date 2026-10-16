# Features and services aggregator
{ ... }:

{
  imports = [
    ./amdgpu-boost.nix
    ./syncthing.nix
    ./chulawifi.nix
    ./openssh.nix
    ./sops.nix
  ];
}
