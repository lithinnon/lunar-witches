# Hardware modules aggregator
{ ... }:

{
  imports = [
    ./cpu/amd.nix
    ./gpu/amd.nix
    ./gpu/amd-integrated.nix
    ./memory/zswap.nix
    ./bluetooth.nix
    ./oem/asus/base.nix
    ./oem/asus/laptop.nix
    ./peripherals/yubikey.nix
    ./peripherals/keychron.nix
  ];
}
