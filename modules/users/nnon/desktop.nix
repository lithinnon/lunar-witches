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
  ];

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

  xdg.mime.enable = true;

  home.activation.updateMimeDatabase = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.shared-mime-info}/bin/update-mime-database $VERBOSE_ARG "''${XDG_DATA_HOME:-$HOME/.local/share}/mime"
  '';

  xdg.dataFile."mime/packages/digital.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-digital">
        <comment>Digital Logic Circuit</comment>
        <icon name="digital"/>
        <glob pattern="*.dig" weight="80"/>
        <root-XML namespaceURI="" localName="circuit"/>
        <sub-class-of type="application/xml"/>
      </mime-type>
      <mime-type type="text/x-digital">
        <comment>Digital Logic Circuit</comment>
        <icon name="digital"/>
        <glob pattern="*.dig" weight="80"/>
        <root-XML namespaceURI="" localName="circuit"/>
        <sub-class-of type="application/xml"/>
      </mime-type>
      <mime-type type="application/x-digital-testcase">
        <comment>Digital Test Case</comment>
        <icon name="digital"/>
        <glob pattern="*.tru" weight="80"/>
        <sub-class-of type="text/plain"/>
      </mime-type>
    </mime-info>
  '';

  xdg.desktopEntries.digital = {
    name = "Digital";
    genericName = "Digital Logic Simulator";
    comment = "Easy-to-use digital logic designer and circuit simulator";
    exec = "digital %F";
    icon = "digital";
    terminal = false;
    type = "Application";
    categories = [
      "Education"
      "Electronics"
    ];
    mimeType = [
      "application/x-digital"
      "text/x-digital"
      "application/x-digital-testcase"
    ];
  };

  xdg.desktopEntries.google-calendar = {
    name = "Google Calendar";
    genericName = "Calendar";
    comment = "Open Google Calendar in default browser";
    exec = "xdg-open https://calendar.google.com";
    icon = "office-calendar";
    terminal = false;
    type = "Application";
    categories = [
      "Office"
      "Calendar"
    ];
  };

  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "application/x-digital" = [ "digital.desktop" ];
      "text/x-digital" = [ "digital.desktop" ];
      "application/x-digital-testcase" = [ "digital.desktop" ];
    };
    defaultApplications = {
      "application/x-digital" = "digital.desktop";
      "text/x-digital" = "digital.desktop";
      "application/x-digital-testcase" = "digital.desktop";
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/mailto" = "brave-browser.desktop";
      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "application/x-matroska" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "x-scheme-handler/antigravity" = "antigravity-ide.desktop";
      "x-scheme-handler/curseforge" = "org.prismlauncher.PrismLauncher.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/lemonade" = "lemonade-app-handler.desktop";
      "x-scheme-handler/mongodb" = "mongodb-compass.desktop";
      "x-scheme-handler/mongodb+srv" = "mongodb-compass.desktop";
      "x-scheme-handler/ror2mm" = "r2modman.desktop";
      "x-scheme-handler/sgdb" = "com.steamgriddb.SGDBoop.desktop";
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";
    };
  };

  programs.plasma-service-deck = {
    enable = true;
    groups = [
      {
        id = "hardware";
        name = "Hardware";
        icon = "preferences-system-hardware";
        services = [
          {
            id = "asusd.service";
            name = "ASUS Control";
            scope = "system";
          }
        ];
      }
      {
        id = "network";
        name = "Network";
        icon = "network-workgroup";
        services = [
          {
            id = "app-org.kde.kdeconnect.daemon@autostart.service";
            display_id = "kdeconnect.service";
            name = "KDE Connect";
            scope = "user";
          }
          {
            id = "syncthing.service";
            name = "Syncthing File Sync";
            scope = "system";
          }
        ];
      }
      {
        id = "ai";
        name = "AI";
        icon = "applications-science";
        services = [
          {
            id = "sillytavern.service";
            name = "SillyTavern";
            scope = "user";
          }
          {
            id = "llama-swap.service";
            name = "llama-swap";
            scope = "user";
          }
          {
            id = "open-webui.service";
            name = "Open WebUI";
            scope = "system";
          }
          {
            id = "deepseek-harness.service";
            name = "DeepSeek Harness";
            scope = "user";
          }
        ];
      }
    ];
  };

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
      <entry>
        <string>wireToolTips</string>
        <boolean>true</boolean>
      </entry>
    </attributes>
  '';
}
