# Form factor role: Laptop
{ self, ... }:

{
  flake.nixosModules.role-laptop =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.boot-systemd
      ];

      networking.networkmanager = {
        enable = true;
        wifi.powersave = false;
        plugins = with pkgs; [
          networkmanager-openvpn
        ];
      };

      # Do not stop NetworkManager before activation; restart it atomically after activation finishes
      systemd.services.NetworkManager.stopIfChanged = false;

      services.power-profiles-daemon.enable = lib.mkDefault true;

      systemd.tmpfiles.rules = [
        "z /sys/firmware/acpi/platform_profile 0666 root root -"
      ];

      environment.systemPackages = [
        pkgs.sync-power-state
      ];
    };
}
