# Peripheral trait: YubiKey (SmartCard Daemon & CCID/FIDO2 Udev Rules)
{ ... }:

{
  flake.nixosModules.hw-peripheral-yubikey = { pkgs, ... }: {
    services.pcscd.enable = true;
    services.udev.packages = with pkgs; [
      yubikey-personalization
    ];
    environment.systemPackages = with pkgs; [
      yubikey-manager
    ];
  };
}
