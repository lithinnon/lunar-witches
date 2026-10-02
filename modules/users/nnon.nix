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

        home-manager.sharedModules = [
          inputs.plasma-manager.homeModules.plasma-manager
        ];

        home-manager.users.nnon =
          { osConfig, ... }:
          {
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
            pkgs.espresso
            pkgs.service-deck-helper
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

          programs.vscode = {
            enable = true;
            profiles.default = {
              userSettings = {
                "files.autoSave" = "afterDelay";
                "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font Mono'";
                "terminal.integrated.cursorBlinking" = true;
                "terminal.integrated.enableImages" = true;
                "terminal.integrated.mouseWheelZoom" = true;
                "terminal.integrated.smoothScrolling" = true;
                "editor.mouseWheelZoom" = true;
                "workbench.iconTheme" = "vscode-icons";
                "terminal.integrated.gpuAcceleration" = "off";
                "redhat.telemetry.enabled" = false;
                "terminal.integrated.fontSize" = 13;
                "editor.formatOnSave" = true;
                "terminal.integrated.enableMultiLinePasteWarning" = "never";
                "chat.disableAIFeatures" = true;
                "workbench.settings.showAISearchToggle" = false;
              };
              extensions = with pkgs.vscode-extensions; [
                arrterian.nix-env-selector
                divyanshuagrawal.competitive-programming-helper
                jnoortheen.nix-ide
                vscode-icons-team.vscode-icons
              ];
            };
          };

          programs.fastfetch = {
            enable = true;
            settings = {
              "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json";
              logo = {
                type = "auto";
                source = "/home/nnon/Documents/Stella Glow/Marie-Eve Assets/LINE Stickers/Marie/4x/Neutral.png";
                width = 32;
              };
              modules = [
                "title"
                "separator"
                "os"
                "host"
                "kernel"
                "uptime"
                "packages"
                "shell"
                "display"
                "de"
                "wm"
                "wmtheme"
                "theme"
                "icons"
                "font"
                "cursor"
                "terminal"
                "terminalfont"
                "cpu"
                "gpu"
                "memory"
                "swap"
                "disk"
                "localip"
                "battery"
                "poweradapter"
                "locale"
                "break"
                "colors"
              ];
            };
          };

          programs.btop = {
            enable = true;
            settings = {
              color_theme = "Default";
              theme_background = true;
              update_ms = 2000;
              shown_boxes = "cpu mem net proc";
              proc_sorting = "cpu lazy";
              proc_colors = true;
              proc_gradient = true;
              proc_mem_bytes = true;
              proc_cpu_graphs = true;
              show_uptime = true;
              show_cpu_watts = true;
              check_temp = true;
              show_coretemp = true;
              show_cpu_freq = true;
              show_swap = true;
              swap_disk = true;
              show_battery = true;
              show_battery_watts = true;
              gpu_mirror_graph = true;
              rsmi_measure_pcie_speeds = true;
              shown_gpus = "nvidia amd intel apple";
            };
          };

          xdg.userDirs = {
            enable = true;
            createDirectories = true;
            desktop = "$HOME/Desktop";
            documents = "$HOME/Documents";
            download = "$HOME/Downloads";
            music = "$HOME/Music";
            pictures = "$HOME/Pictures";
            videos = "$HOME/Videos";
            templates = "$HOME/Templates";
            publicShare = null;
            extraConfig = {
              XDG_PROJECTS_DIR = "$HOME/Projects";
            };
          };

          xdg.mimeApps = {
            enable = true;
            defaultApplications = {
              "text/html" = "brave-browser.desktop";
              "x-scheme-handler/http" = "brave-browser.desktop";
              "x-scheme-handler/https" = "brave-browser.desktop";
              "x-scheme-handler/mailto" = "brave-browser.desktop";
              "application/x-matroska" = "mpv.desktop";
              "application/xml" = "digital.desktop";
              "audio/x-iriver-pla" = "org.kde.kate.desktop";
              "video/3gp" = "mpv.desktop";
              "video/3gpp" = "mpv.desktop";
              "video/3gpp2" = "mpv.desktop";
              "video/avi" = "mpv.desktop";
              "video/divx" = "mpv.desktop";
              "video/dv" = "mpv.desktop";
              "video/fli" = "mpv.desktop";
              "video/flv" = "mpv.desktop";
              "video/mp2t" = "mpv.desktop";
              "video/mp4" = "mpv.desktop";
              "video/mp4v-es" = "mpv.desktop";
              "video/mpeg" = "mpv.desktop";
              "video/msvideo" = "mpv.desktop";
              "video/ogg" = "mpv.desktop";
              "video/quicktime" = "mpv.desktop";
              "video/vnd.divx" = "mpv.desktop";
              "video/vnd.mpegurl" = "mpv.desktop";
              "video/vnd.rn-realvideo" = "mpv.desktop";
              "video/webm" = "mpv.desktop";
              "video/x-avi" = "mpv.desktop";
              "video/x-flv" = "mpv.desktop";
              "video/x-m4v" = "mpv.desktop";
              "video/x-matroska" = "mpv.desktop";
              "video/x-mpeg2" = "mpv.desktop";
              "video/x-ms-asf" = "mpv.desktop";
              "video/x-ms-wmv" = "mpv.desktop";
              "video/x-ms-wmx" = "mpv.desktop";
              "video/x-msvideo" = "mpv.desktop";
              "video/x-ogm" = "mpv.desktop";
              "video/x-ogm+ogg" = "mpv.desktop";
              "video/x-theora" = "mpv.desktop";
              "video/x-theora+ogg" = "mpv.desktop";
              "x-scheme-handler/antigravity" = "antigravity-app.desktop";
              "x-scheme-handler/curseforge" = "org.prismlauncher.PrismLauncher.desktop";
              "x-scheme-handler/discord" = "vesktop.desktop";
              "x-scheme-handler/discord-562286213059444737" = "lunarclient.desktop";
              "x-scheme-handler/hermes" = "Hermes.desktop";
              "x-scheme-handler/lemonade" = "lemonade-app-handler.desktop";
              "x-scheme-handler/lunarclient" = "lunarclient.desktop";
              "x-scheme-handler/mongodb" = "mongodb-compass.desktop";
              "x-scheme-handler/mongodb+srv" = "mongodb-compass.desktop";
              "x-scheme-handler/sgdb" = "com.steamgriddb.SGDBoop.desktop";
              "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
              "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
            };
          };

          # Declarative KDE Plasma Management (via plasma-manager)
          programs.plasma = {
            enable = osConfig.services.desktopManager.plasma6.enable;
            overrideConfig = false;

            input.keyboard = {
              numlockOnStartup = "off";
              repeatDelay = 288;
              repeatRate = 40.0;
            };

            kwin = {
              virtualDesktops = {
                number = 2;
                rows = 1;
              };
            };

            shortcuts = {
              "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Alt+Shift";
              "com.dec05eba.gpu_screen_recorder" = {
                "gpu_screen_recorder_pause_unpause_recording" = "Alt+2";
                "gpu_screen_recorder_save_replay" = "Alt+3";
                "gpu_screen_recorder_start_stop_recording" = "Alt+1";
              };
              kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
              kmix = {
                "decrease_microphone_volume" = "Microphone Volume Down";
                "decrease_volume" = "Volume Down";
                "decrease_volume_small" = "Shift+Volume Down";
                "increase_microphone_volume" = "Microphone Volume Up";
                "increase_volume" = "Volume Up";
                "increase_volume_small" = "Shift+Volume Up";
                "mic_mute" = [
                  "Microphone Mute"
                  "Meta+Volume Mute"
                ];
                "mute" = "Volume Mute";
              };
              ksmserver = {
                "Lock Session" = [
                  "Screensaver"
                  "Meta+L"
                ];
                "Log Out" = "Ctrl+Alt+Del";
              };
              kwin = {
                "Activate Window Demanding Attention" = "Meta+Ctrl+A";
                "Edit Tiles" = "Meta+T";
                "Expose" = [
                  "Ctrl+F9"
                  "Meta+F9"
                ];
                "ExposeAll" = [
                  "Launch (C)"
                  "Ctrl+F10"
                  "Meta+F10"
                ];
                "ExposeClass" = [
                  "Ctrl+F7"
                  "Meta+F7"
                ];
                "Grid View" = "Meta+G";
                "Kill Window" = "Meta+Ctrl+Esc";
                "MoveMouseToCenter" = "Meta+F6";
                "MoveMouseToFocus" = "Meta+F5";
                "Overview" = "Meta+W";
                "Show Desktop" = "Meta+D";
                "Switch One Desktop Down" = "Meta+Ctrl+Down";
                "Switch One Desktop Up" = "Meta+Ctrl+Up";
                "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
                "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
                "Switch Window Down" = "Meta+Alt+Down";
                "Switch Window Left" = "Meta+Alt+Left";
                "Switch Window Right" = "Meta+Alt+Right";
                "Switch Window Up" = "Meta+Alt+Up";
                "Switch to Desktop 1" = "Ctrl+F1";
                "Switch to Desktop 2" = "Ctrl+F2";
                "Switch to Desktop 3" = "Ctrl+F3";
                "Switch to Desktop 4" = "Ctrl+F4";
                "Walk Through Windows" = [
                  "Alt+Tab"
                  "Meta+Tab"
                ];
                "Walk Through Windows (Reverse)" = [
                  "Alt+Shift+Tab"
                  "Meta+Shift+Tab"
                ];
                "Walk Through Windows of Current Application" = [
                  "Alt+`"
                  "Meta+`"
                ];
                "Walk Through Windows of Current Application (Reverse)" = [
                  "Alt+~"
                  "Meta+~"
                ];
                "Window Close" = "Alt+F4";
                "Window Maximize" = "Meta+PgUp";
                "Window Minimize" = "Meta+PgDown";
                "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
                "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
                "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
                "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
                "Window Operations Menu" = "Alt+F3";
                "Window Quick Tile Bottom" = "Meta+Down";
                "Window Quick Tile Left" = "Meta+Left";
                "Window Quick Tile Right" = "Meta+Right";
                "Window Quick Tile Top" = "Meta+Up";
                "Window Restore" = "Meta+Backspace";
                "Window to Next Screen" = "Meta+Shift+Right";
                "Window to Previous Screen" = "Meta+Shift+Left";
                "disableInputCapture" = "Meta+Shift+Esc";
                "view_actual_size" = "Meta+0";
                "view_zoom_in" = [
                  "Meta++"
                  "Meta+="
                ];
                "view_zoom_out" = "Meta+-";
              };
              mediacontrol = {
                "nextmedia" = "Media Next";
                "pausemedia" = "Media Pause";
                "playpausemedia" = [
                  "Media Play"
                  "Launch (4)"
                ];
                "previousmedia" = "Media Previous";
                "seekbackwardmedia" = "Media Rewind";
                "seekforwardmedia" = "Media Fast Forward";
                "stopmedia" = "Media Stop";
              };
              org_kde_powerdevil = {
                "Decrease Keyboard Brightness" = "Keyboard Brightness Down";
                "Decrease Screen Brightness" = "Monitor Brightness Down";
                "Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
                "Hibernate" = "Hibernate";
                "Increase Keyboard Brightness" = "Keyboard Brightness Up";
                "Increase Screen Brightness" = "Monitor Brightness Up";
                "Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
                "PowerDown" = "Power Down";
                "PowerOff" = "Power Off";
                "Sleep" = "Sleep";
                "Toggle Keyboard Backlight" = "Keyboard Light On/Off";
                "powerProfile" = [
                  "Battery"
                  "Meta+B"
                ];
              };
              plasmashell = {
                "activate application launcher" = [
                  "Meta"
                  "Alt+F1"
                ];
                "activate task manager entry 1" = "Meta+1";
                "activate task manager entry 2" = "Meta+2";
                "activate task manager entry 3" = "Meta+3";
                "activate task manager entry 4" = "Meta+4";
                "activate task manager entry 5" = "Meta+5";
                "activate task manager entry 6" = "Meta+6";
                "activate task manager entry 7" = "Meta+7";
                "activate task manager entry 8" = "Meta+8";
                "activate task manager entry 9" = "Meta+9";
                "clipboard_action" = "Meta+Ctrl+X";
                "cycle-panels" = "Meta+Alt+P";
                "manage activities" = "Meta+Q";
                "next activity" = "Meta+A";
                "previous activity" = "Meta+Shift+A";
                "show dashboard" = "Ctrl+F12";
                "show-on-mouse-pos" = "Meta+V";
              };
              "services/org.kde.kate.desktop"._launch = "Meta+Shift+Q";
              "services/org.localsend.localsend_app.desktop"._launch = "Meta+Shift+L";
              "services/rog-control-center.desktop"._launch = "Launch (3)";
              "services/systemsettings.desktop"._launch = "Tools";
            };

            configFile = {
              "kcminputrc" = {
                "Libinput/10248/592/ASCF1206:00 2808:0250 Mouse" = {
                  PointerAcceleration = "0.000";
                  PointerAccelerationProfile = 2;
                };
                "Libinput/10248/592/ASCF1206:00 2808:0250 Touchpad" = {
                  ClickMethod = 2;
                  DisableEventsOnExternalMouse = false;
                  DisableWhileTyping = false;
                  Enabled = false;
                  LmrTapButtonMap = false;
                  NaturalScroll = true;
                  PointerAcceleration = "0.400";
                  PointerAccelerationProfile = 2;
                  ScrollFactor = "0.5";
                };
                "Libinput/13364/53348/Keychron Keychron M6" = {
                  PointerAcceleration = "0.200";
                  PointerAccelerationProfile = 1;
                };
                "Libinput/5426/152/Razer Razer DeathAdder Essential" = {
                  PointerAcceleration = "-0.100";
                  PointerAccelerationProfile = 1;
                };
              };
              "kwinrc" = {
                Wayland = {
                  VirtualKeyboardEnabled = true;
                  VirtualKeyboardMode = 1;
                };
                Xwayland = {
                  Scale = 1;
                  XwaylandEisNoPrompt = true;
                };
              };
              "kdeglobals" = {
                General = {
                  AccentColor = "132,250,216";
                  BrowserApplication = "brave-browser.desktop";
                  LastUsedCustomAccentColor = "132,250,216";
                };
              };
              "powerdevilrc" = {
                "AC/Performance".PowerProfile = "performance";
                "AC/RunScript".ProfileLoadCommand = "/run/current-system/sw/bin/sync-power-state ac";
                "AC/SuspendAndShutdown".LidAction = 0;
                "Battery/Performance".PowerProfile = "balanced";
                "Battery/RunScript".ProfileLoadCommand = "/run/current-system/sw/bin/sync-power-state battery";
                "Inhibitions".BlockedInhibitions = "/opt/brave.com/brave/brave:Video Wake Lock";
                "LowBattery/Performance".PowerProfile = "power-saver";
                "LowBattery/SuspendAndShutdown".InhibitLidActionWhenExternalMonitorPresent = false;
              };
            };
          };

          xdg.configFile."plasma-service-deck.json".text = ''
            {
              "groups": [
                {
                  "id": "hardware",
                  "name": "Hardware",
                  "icon": "preferences-system-hardware",
                  "services": [
                    {
                      "id": "amdgpu-boost.service",
                      "name": "AMD GPU Boost",
                      "scope": "user"
                    },
                    {
                      "id": "asusd.service",
                      "name": "ASUS Notebook Control",
                      "scope": "system"
                    }
                  ]
                },
                {
                  "id": "network",
                  "name": "Network",
                  "icon": "network-workgroup",
                  "services": [
                    {
                      "id": "app-org.kde.kdeconnect.daemon@autostart.service",
                      "display_id": "kdeconnect.service",
                      "name": "KDE Connect",
                      "scope": "user"
                    },
                    {
                      "id": "syncthing.service",
                      "name": "Syncthing File Sync",
                      "scope": "system"
                    }
                  ]
                }
              ],
              "ungrouped": {
                "name": "Ungrouped",
                "icon": "package-x-generic",
                "services": [
                  {
                    "id": "kde-baloo.service",
                    "name": "Baloo File Indexer",
                    "scope": "user"
                  }
                ]
              }
            }
          '';

          home.file.".digital.cfg".text = ''
            <?xml version="1.0" encoding="utf-8"?>
            <attributes>
              <entry>
                <string>showTutorial</string>
                <boolean>false</boolean>
              </entry>
              <entry>
                <string>colorScheme</string>
                <de.neemann.digital.draw.graphics.ColorScheme_-ColorSchemes>DARK</de.neemann.digital.draw.graphics.ColorScheme_-ColorSchemes>
              </entry>
            </attributes>
          '';

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
