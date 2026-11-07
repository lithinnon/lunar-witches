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
        nix = {
          settings = {
            use-xdg-base-directories = true;
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            auto-optimise-store = true;
            trusted-users = [
              "root"
              "@wheel"
            ];
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
              "https://nyx-cache.chaotic.cx"
              "https://ezkea.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
              "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
            ];
          };
        };

        programs.nh = {
          enable = true;
          clean = {
            enable = true;
            extraArgs = "--keep-since 4d --keep 3";
          };
          flake = config.core.flakePath;
        };

        programs.fish.enable = true;
        programs.ssh.startAgent = true;
        environment.localBinInPath = true;

        # Graphical AskPass passthrough for KDE ksshaskpass
        security.sudo.extraConfig = ''
          Defaults passprompt_override,env_keep+="SUDO_ASKPASS"
        '';

        # Unlimited locked memory for hardware accelerators (NPU DMA, ROCm, io_uring, audio)
        security.pam.loginLimits = [
          {
            domain = "*";
            item = "memlock";
            type = "-";
            value = "unlimited";
          }
        ];
        systemd.settings.Manager.DefaultLimitMEMLOCK = "infinity";
        systemd.user.settings.Manager.DefaultLimitMEMLOCK = "infinity";

        time.timeZone = config.core.timeZone;
        i18n.defaultLocale = config.core.defaultLocale;

        environment.systemPackages = with pkgs; [
          curl
          wget
          git
          neovim
          fastfetch
          pciutils
          usbutils
          nftables
          wireguard-tools
          openvpn
          python3
          btrfs-progs
          zip
          unzip
        ];

        system.stateVersion = "26.05";
      };
    };
}
