# OEM trait: ASUS Laptop Platform (Panel overdrive, thermal throttle sysfs)
{ self, ... }:

{
  flake.nixosModules.hw-oem-asus-laptop = { ... }: {
    imports = [
      self.nixosModules.hw-oem-asus-base
    ];

    systemd.tmpfiles.rules = [
      "z /sys/devices/platform/asus-nb-wmi/panel_od 0666 root root -"
      "z /sys/devices/platform/asus-nb-wmi/throttle_thermal_policy 0666 root root -"
    ];
  };
}
