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
        authfile = lib.mkDefault "/etc/u2f_keys";
        debug = lib.mkDefault true;
      };
    };

    environment.etc."u2f_keys" = {
      text = "nnon:i9ZVWQd92KtgoxcMZUG/Zh7igh8Nx0mcxxrrXQo5xKiLrnV+Ot497Vv5di/jdJs5DCYdwtLgFvvANkSFPTyL7w==,k12MeAlI/OZFtNNGrMJ65Y5EFaaq7rRGybsHxjwM1/7W7CVYtc1Rztn1N5ZLHWbQeN2s2JsbafaaK6F4I/3Urg==,es256,+presence\n";
      mode = "0644";
    };

    security.pam.services.sudo.u2f.enable = lib.mkDefault true;
    security.pam.services.polkit-1.u2f.enable = lib.mkDefault true;

    # Polkit 127 sandboxes polkit-agent-helper@ with PrivateDevices=yes, DevicePolicy=strict,
    # and DeviceAllow=/dev/null rw, blocking pam_u2f from /dev/urandom and /dev/hidraw* (YubiKey USB HID).
    systemd.services."polkit-agent-helper@" = {
      serviceConfig = {
        PrivateDevices = false;
        DevicePolicy = "auto";
        DeviceAllow = [
          ""
          "char-* rw"
        ];
        ProtectHome = false;
      };
    };
  };
}
