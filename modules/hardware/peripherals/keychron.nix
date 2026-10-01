# Peripheral trait: Keychron mice & wireless peripherals (VID 3434)
{ ... }:

{
  flake.nixosModules.hw-peripheral-keychron = { ... }: {
    services.udev.extraRules = ''
      # Keychron M6 Mouse (USB/Dongle)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="d064", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

      # General Keychron Device (VID 3434)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}
