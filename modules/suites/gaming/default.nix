# Capability suite: Dedicated Gaming, Steam, GameScope & Anime Launchers
{ inputs, ... }:

{
  flake.nixosModules.suite-gaming = { pkgs, ... }: {
    imports = [
      inputs.aagl.nixosModules.default
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = true;
    };

    # AAGL (Anime Game Launcher on Nix)
    nix.settings = inputs.aagl.nixConfig;
    programs.honkers-launcher.enable = true;

    environment.systemPackages = with pkgs; [
      inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
      mangohud
      protonplus
      sgdboop
    ];
  };
}
