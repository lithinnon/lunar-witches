# Feature profile: Syncthing Continuous File Synchronization
{ ... }:

{
  flake.nixosModules.feature-syncthing =
    { config, lib, ... }:
    let
      cfg = config.services.syncthing;
      userHome =
        if cfg.user != null && config.users.users ? ${cfg.user} then
          config.users.users.${cfg.user}.home
        else
          "/home/${cfg.user}";
    in
    {
      services.syncthing = lib.mkIf cfg.enable {
        user = lib.mkDefault "nnon";
        dataDir = lib.mkDefault "${userHome}/Sync";
        configDir = lib.mkDefault "${userHome}/.local/state/syncthing";
        openDefaultPorts = lib.mkDefault true;
      };

      systemd.services.syncthing.serviceConfig = lib.mkIf cfg.enable {
        Nice = 19;
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
      };
    };
}
