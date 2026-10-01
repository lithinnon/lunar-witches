# Dendritic Core System Foundation (Universal for servers, laptops, desktops)
{ ... }:

{
  flake.nixosModules.core =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.core = {
        flakePath = lib.mkOption {
          type = lib.types.str;
          default = "/home/nnon/lunar-witches";
          description = "Path to the system flake repository for nh.";
        };
        timeZone = lib.mkOption {
          type = lib.types.str;
          default = "Asia/Bangkok";
          description = "System timezone.";
        };
        defaultLocale = lib.mkOption {
          type = lib.types.str;
          default = "en_US.UTF-8";
          description = "Default system locale.";
        };
      };

      config = {
        # Nix Flakes & Package Manager Settings
        nix = {
          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            auto-optimise-store = true;
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
              "https://attic.xuyh0120.win/lantian"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            ];
          };
        };

        # nh (Yet Another Nix Helper) cache retention
        programs.nh = {
          enable = true;
          clean = {
            enable = true;
            extraArgs = "--keep-since 4d --keep 3";
          };
          flake = config.core.flakePath;
        };

        # Shell Foundation
        programs.fish.enable = true;
        environment.localBinInPath = true;

        # Security & Sudo AskPass Configuration
        security.sudo.extraConfig = ''
          Defaults passprompt_override,env_keep+="SUDO_ASKPASS"
        '';

        # Timezone and Localization
        time.timeZone = config.core.timeZone;
        i18n.defaultLocale = config.core.defaultLocale;

        # Essential System CLI Utilities
        environment.systemPackages = with pkgs; [
          curl
          wget
          git
          neovim
          htop
          fastfetch
          pciutils
          usbutils
          nftables
          wireguard-tools
          openvpn
          python3
          btrfs-progs
        ];

        system.stateVersion = "26.05";
      };
    };
}
