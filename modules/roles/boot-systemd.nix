# UEFI bootloader role via systemd-boot
{ ... }:

{
  flake.nixosModules.boot-systemd = { ... }: {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
