# Capability suite: Dedicated Gaming, Steam, GameScope & Anime Launchers
{ inputs, ... }:

{
  flake.nixosModules.suite-gaming = { pkgs, ... }: {
    imports = [
      inputs.aagl.nixosModules.default
    ];

    # Steam with 32-bit graphics bridge, GameScope, and remote play firewall
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = true;
    };

    # AAGL (Anime Game Launcher on Nix)
    nix.settings = inputs.aagl.nixConfig;
    programs.honkers-launcher.enable = true;

    # Gaming & Compatibility Utilities
    environment.systemPackages = with pkgs; [
      inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
      mangohud
      protonplus
      sgdboop
    ];
  };
}
