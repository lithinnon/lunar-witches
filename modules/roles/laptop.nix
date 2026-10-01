# Form factor role: Laptop
{ self, ... }:

{
  flake.nixosModules.role-laptop = { config, lib, pkgs, ... }: {
    imports = [
      self.nixosModules.boot-systemd
    ];

    # Dynamic network management for roving WiFi/Ethernet
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };

    # Power & battery profile management
    services.power-profiles-daemon.enable = lib.mkDefault true;

    # Dynamic refresh rate and power switching utility
    environment.systemPackages = [
      pkgs.sync-power-state
    ];
  };
}
