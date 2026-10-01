# Form factor role: Stationary Desktop PC
{ self, ... }:

{
  flake.nixosModules.role-desktop = { config, lib, pkgs, ... }: {
    imports = [
      self.nixosModules.boot-systemd
    ];

    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };
  };
}
