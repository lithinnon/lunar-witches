# Peripheral trait: YubiKey (SmartCard Daemon, CCID/FIDO2 Udev Rules & PAM U2F)
{ ... }:

{
  flake.nixosModules.hw-peripheral-yubikey = { pkgs, lib, ... }: {
    services.pcscd.enable = true;
    services.udev.packages = with pkgs; [
      yubikey-personalization
    ];
    environment.systemPackages = with pkgs; [
      yubikey-manager
      pam_u2f
    ];

    security.pam.u2f = {
      enable = false;
      control = lib.mkDefault "sufficient";
      settings = {
        cue = lib.mkDefault true;
      };
    };

    security.pam.services.sudo.u2f.enable = lib.mkDefault true;
    security.pam.services.polkit-1.u2f.enable = lib.mkDefault true;
  };
}
