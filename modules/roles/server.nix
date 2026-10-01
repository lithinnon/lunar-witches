# Form factor role: Headless Server
{ ... }:

{
  flake.nixosModules.role-server = { config, lib, ... }: {
    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;
  };
}
