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

      services.power-profiles-daemon.enable = lib.mkDefault true;

      environment.systemPackages = [
        pkgs.sync-power-state
      ];
    };
}
