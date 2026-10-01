# Opt-in feature: Syncthing Continuous File Synchronization
{ ... }:

{
  flake.nixosModules.feature-syncthing = { config, lib, ... }:
  let
    cfg = config.services.lunar-syncthing;
  in {
    options.services.lunar-syncthing = {
      enable = lib.mkEnableOption "Syncthing continuous file synchronization";

      user = lib.mkOption {
        type = lib.types.str;
        default = "nnon";
        description = "User to run Syncthing under.";
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/home/nnon/Sync";
        description = "Primary synchronization directory.";
      };

      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/home/nnon/.local/state/syncthing";
        description = "Syncthing configuration directory.";
      };
    };

    config = lib.mkIf cfg.enable {
      services.syncthing = {
        enable = true;
        user = cfg.user;
        dataDir = cfg.dataDir;
        configDir = cfg.configDir;
        openDefaultPorts = true;
      };
    };
  };
}
