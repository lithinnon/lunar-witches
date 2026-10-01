# User profile module: nnon
{ inputs, ... }:

{
  flake.nixosModules.user-nnon =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.users.nnon = {
        gitSigningKey = lib.mkOption {
          type = lib.types.str;
          default = "9106CA7732D04633";
          description = "GPG signing key ID for user nnon.";
        };

        chulawifiIdentity = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "6933200721";
          description = "Chulalongkorn University student/staff ID for user nnon.";
        };

        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvk/9JeTPOjRQqe3FPz0fluRQ4OvXfCwARekR0po3QI DESKTOP-E3G9LEN"
          ];
          description = "SSH authorized public keys for user nnon.";
        };
      };

      config = {
        users.users.nnon = {
          isNormalUser = true;
          description = "nnon";
          openssh.authorizedKeys.keys = config.users.nnon.authorizedKeys;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "render"
            "audio"
            "input"
          ];
          shell = pkgs.fish;
        };

        home-manager.users.nnon = {
          home.username = "nnon";
          home.homeDirectory = "/home/nnon";
          home.sessionPath = [
            "$HOME/.local/bin"
          ];
          home.sessionVariables = {
            NH_SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
            SSH_ASKPASS_REQUIRE = "prefer";
          };

          home.shellAliases = {
            amdgpu-reset = "sudo -A cat /sys/kernel/debug/dri/1/amdgpu_gpu_recover";
            mesa-vk-trace = "touch /tmp/mesa_vk_trace_trigger";
            ".." = "cd ..";
            "..." = "cd ...";
            cls = "clear";
            vi = "nvim";
            vim = "nvim";
            g = "git";
            cp = "cp -i";
            mv = "mv -i";
            gq = "ghq get --update -p --look --parallel";
            setup-optiscaler = "chmod +x ./setup_linux.sh && ./setup_linux.sh";
          };

          programs.fish = {
            enable = true;
            shellInit = ''
              # Load unmanaged user secrets if present (supports KEY=VALUE and export KEY=VALUE)
              if test -f "$HOME/.config/secrets.env"
                for line in (cat "$HOME/.config/secrets.env" | string match -r "^(export\\s+)?[^#\\s=]+=[^\\n]*")
                  set -l clean (string replace -r "^export\\s+" "" $line)
                  set -l kv (string split -m 1 = $clean)
                  if test (count $kv) -eq 2
                    set -l val (string trim -c "\"'" "$kv[2]")
                    set -gx $kv[1] $val
                  end
                end
              end
            '';
            interactiveShellInit = ''
              set -g fish_greeting
            '';
          };

          programs.bash = {
            enable = true;
            initExtra = ''
              # Load unmanaged user secrets if present
              if [ -f "$HOME/.config/secrets.env" ]; then
                set -a
                source "$HOME/.config/secrets.env"
                set +a
              fi
            '';
          };

          home.packages = [
            inputs.bullvpn.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];

          # AMD GPU Boost background service (D-Bus event-driven clock manager)
          systemd.user.services.amdgpu-boost = lib.mkIf config.services.amdgpu-boost.enable {
            Unit = {
              Description = "AMD GPU Performance Boost & DPM Manager Daemon";
              After = [
                "graphical-session.target"
                "asusd.service"
              ];
            };
            Service = {
              Type = "simple";
              ExecStart = "${pkgs.amdgpu-boost}/bin/amdgpu-boost --daemon";
              Restart = "always";
              RestartSec = 2;
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };

          programs.vscode.enable = true;

          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            settings = {
              "*" = {
                AddKeysToAgent = "yes";
              };
              "white" = {
                HostName = "10.10.0.7";
                IdentityFile = "~/.ssh/other-keys/DESKTOP-E3G9LEN/id_ed25519";
              };
              "i2cedt-2" = {
                HostName = "ec2-3-94-117-168.compute-1.amazonaws.com";
                User = "ubuntu";
              };
            };
          };

          programs.git = {
            enable = true;
            signing = {
              key = config.users.nnon.gitSigningKey;
              signByDefault = true;
            };
            settings = {
              user = {
                name = "lithinnon";
                email = "49898465+lithinnon@users.noreply.github.com";
              };
              init.defaultBranch = "master";
              safe.directory = "*";
            };
          };

          programs.gpg = {
            enable = true;
            mutableKeys = true;
            mutableTrust = true;
            settings = {
              personal-cipher-preferences = "AES256 AES192 AES";
              personal-digest-preferences = "SHA512 SHA384 SHA256";
              personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
              default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
              cert-digest-algo = "SHA512";
              s2k-digest-algo = "SHA512";
              s2k-cipher-algo = "AES256";
              charset = "utf-8";
              no-comments = true;
              no-emit-version = true;
              no-greeting = true;
              keyid-format = "0xlong";
              with-fingerprint = true;
              list-options = "show-uid-validity";
              verify-options = "show-uid-validity";
              use-agent = true;
            };
          };

          services.gpg-agent = {
            enable = true;
            enableFishIntegration = true;
            enableBashIntegration = true;
            enableScDaemon = true;
            pinentry.package = pkgs.pinentry-qt;
            defaultCacheTtl = 3600;
            maxCacheTtl = 86400;
          };

          programs.home-manager.enable = true;
          home.stateVersion = "26.05";
        };
      };
    };
}
