# Aggregator for form factor roles
{ ... }:

{
  imports = [
    ./boot-systemd.nix
    ./laptop.nix
    ./desktop.nix
    ./server.nix
  ];
}
