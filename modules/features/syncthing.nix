# Feature profile: Syncthing Continuous File Synchronization
{ ... }:

{
  flake.nixosModules.feature-syncthing = { config, lib, ... }: {
    # When services.syncthing.enable is true, apply sensible system defaults
    services.syncthing = lib.mkIf config.services.syncthing.enable {
      user = lib.mkDefault "nnon";
      dataDir = lib.mkDefault "/home/nnon/Sync";
      configDir = lib.mkDefault "/home/nnon/.local/state/syncthing";
      openDefaultPorts = lib.mkDefault true;
    };
  };
}
