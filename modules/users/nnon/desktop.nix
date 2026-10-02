# User desktop integration: XDG user dirs, MIME apps, packages, Service Deck, Digital
{
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:

{
  home.packages = [
    inputs.bullvpn.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.espresso
    pkgs.service-deck-helper
  ];

  # AMD GPU Boost background service (D-Bus event-driven clock manager)
  systemd.user.services.amdgpu-boost = lib.mkIf osConfig.services.amdgpu-boost.enable {
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
      PROJECTS = "$HOME/Projects";
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
}
