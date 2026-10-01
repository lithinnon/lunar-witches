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
      };

      config = {
        # NixOS user definition
        users.users.nnon = {
          isNormalUser = true;
          description = "nnon";
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

        # Integrated Home Manager configuration for nnon
        home-manager.users.nnon = {
          home.username = "nnon";
          home.homeDirectory = "/home/nnon";
          home.sessionPath = [
            "$HOME/.local/bin"
          ];

          # Shell Aliases for all shells
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

          # Fish Shell Configuration
          programs.fish = {
            enable = true;
            shellAliases = config.home-manager.users.nnon.home.shellAliases;
            shellInit = ''
              # Ensure ~/.local/bin is always in PATH
              fish_add_path --path --prepend "$HOME/.local/bin"

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
              # Disable fish greeting
              set -g fish_greeting
            '';
          };

          # Bash Shell Configuration
          programs.bash = {
            enable = true;
            shellAliases = config.home-manager.users.nnon.home.shellAliases;
            initExtra = ''
              if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                export PATH="$HOME/.local/bin:$PATH"
              fi

              # Load unmanaged user secrets if present
              if [ -f "$HOME/.config/secrets.env" ]; then
                set -a
                source "$HOME/.config/secrets.env"
                set +a
              fi
            '';
          };

          # Standalone User Packages (e.g. BullVPN)
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

          # Visual Studio Code
          programs.vscode.enable = true;

          # Declarative Git Configuration
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

          # GnuPG (GPG) & SmartCard / YubiKey Agent
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

          # Let Home Manager manage its own installation
          programs.home-manager.enable = true;
          home.stateVersion = "26.05";
        };
      };
    };
}
