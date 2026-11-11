# Capability suite: Dedicated Gaming, Steam, GameScope & Anime Launchers
{ inputs, ... }:

{
  flake.nixosModules.suite-gaming =
    { pkgs, ... }:
    let
      hytale-launcher-pkg = inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default;
      hytale-launcher-wrapped = pkgs.symlinkJoin {
        name = "hytale-launcher-${hytale-launcher-pkg.version}";
        paths = [ hytale-launcher-pkg ];
        postBuild = ''
          for sz in 32x32 48x48 64x64 128x128 256x256; do
            install -Dm644 ${./assets/hytale-icons}/$sz.png \
              $out/share/icons/hicolor/$sz/apps/hytale-launcher.png
          done
        '';
        inherit (hytale-launcher-pkg) meta;
      };
    in
    {
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
      programs.anime-game-launcher.enable = true;
      programs.honkers-launcher.enable = true;

      environment.systemPackages = with pkgs; [
        acg-config-sync
        hytale-launcher-wrapped
        inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
        (prismlauncher.override {
          jdks = with pkgs; [
            temurin-bin-25
            temurin-bin-21
            temurin-bin-17
            temurin-bin-8
          ];
        })
        mangohud
        protonplus
        protontricks
        r2modman
        sgdboop
      ];

      home-manager.sharedModules = [
        {
          systemd.user.services.protonplus = {
            Unit = {
              Description = "ProtonPlus";
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.protonplus}/bin/protonplus update all";
            };
          };

          systemd.user.timers.protonplus = {
            Unit = {
              Description = "ProtonPlus";
            };
            Timer = {
              OnCalendar = "*-*-* 00,12:00:00";
              RandomizedDelaySec = "5m";
              Persistent = true;
            };
            Install = {
              WantedBy = [ "timers.target" ];
            };
          };
        }
      ];
    };
}
