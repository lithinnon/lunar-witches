# Form factor role: Stationary Desktop PC
{ self, ... }:

{
  flake.nixosModules.role-desktop =
    {
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.boot-systemd
      ];

      networking.networkmanager = {
        enable = true;
        plugins = with pkgs; [
          networkmanager-openvpn
        ];
      };

      # Do not stop NetworkManager before activation; restart it atomically after activation finishes
      systemd.services.NetworkManager.stopIfChanged = false;
    };
}
