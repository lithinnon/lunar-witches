# Capability suite: Daily Desktop Utilities & Native Applications
{ inputs, ... }:

{
  flake.nixosModules.suite-desktop-apps = { pkgs, ... }: {
    imports = [
      inputs.nix-craftapps.nixosModules.default
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.brave-browser.nixosModules.default
    ];

    programs.craftapps = {
      enable = true;
      apps.photocraft.enable = true;
      apps.filmcraft.enable = true;
      apps.pdfcraft.enable = true;
    };

    services.flatpak = {
      enable = true;
      uninstallUnmanaged = true;
      update.auto.enable = true;

      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];

      packages = [
        {
          appId = "net.waterfox.waterfox";
          origin = "flathub";
        }
      ];

      # Expose /nix/store so font symlinks resolve and grant Waterfox Plasma browser integration
      overrides.settings = {
        global.Context.filesystems = [ "/nix/store:ro" ];
        "net.waterfox.waterfox"."Session Bus Policy"."org.kde.plasma.browser.integration" = "talk";
      };
    };

    programs.brave = {
      enable = true;
      policy = {
        BraveRewardsDisabled = true;
        BraveWalletDisabled = true;
        BraveVPNDisabled = true;
        BraveNewsDisabled = true;
        BraveAIChatEnabled = true;
        TorDisabled = false;
      };
    };

    programs.localsend = {
      enable = true;
      openFirewall = true;
    };

    programs.kdeconnect.enable = true;
    programs.gpu-screen-recorder.enable = true;

    environment.systemPackages = with pkgs; [
      gpu-screen-recorder-gtk
      yt-dlp
      qbittorrent
      btop
      brave
      # Headless build sandbox lacks fontmanager libraries, failing SVG/GUI font tests
      (digital.overrideAttrs (old: {
        buildPhase = builtins.replaceStrings [ "mvn package" ] [ "mvn package -DskipTests" ] old.buildPhase;
      }))
      (pkgs.runCommand "digital-mime" { } ''
        install -Dm644 ${pkgs.writeText "digital.xml" ''
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
        ''} $out/share/mime/packages/digital.xml

        install -Dm644 ${pkgs.writeText "digital.desktop" ''
          [Desktop Entry]
          Categories=Education;Electronics;
          Comment=Easy-to-use digital logic designer and circuit simulator
          Exec=digital %F
          Icon=digital
          Keywords=simulator;digital;circuits;
          MimeType=application/x-digital;text/x-digital;application/x-digital-testcase;
          Name=Digital
          Terminal=false
          Type=Application
          Version=1.5
        ''} $out/share/applications/digital.desktop
      '')
      # Digital++ — digital-egro
      (
        let
          digitalEgroPkg =
            inputs.digital-egro.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideMavenAttrs
              (_: {
                doCheck = false;
                mvnHash = "sha256-cWm1gdIwc7HSZqvXBUbrdicN9JZusppRdGjr2PptgLQ=";
              });
        in
        pkgs.runCommand "digital-egro" { } ''
          mkdir -p $out/bin $out/share/applications $out/share
          ln -s ${digitalEgroPkg}/bin/digital $out/bin/digital-egro
          ln -s ${digitalEgroPkg}/bin/digital $out/bin/digital++
          cp -r ${digitalEgroPkg}/share/icons $out/share/ 2>/dev/null || true
          install -Dm644 ${pkgs.writeText "digital-egro.desktop" ''
            [Desktop Entry]
            Categories=Education;Electronics;
            Comment=Digital logic circuits (digital-egro)
            Exec=digital-egro %F
            Icon=digital
            Keywords=digital;egro;circuit;
            MimeType=application/x-digital;text/x-digital;application/x-digital-testcase;
            Name=Digital++
            Terminal=false
            Type=Application
            Version=1.5
          ''} $out/share/applications/digital-egro.desktop
        ''
      )
      # AppImage double-click support: shared-mime-info has no AppImage type,
      # so register *.AppImage by glob (weight 90 beats the generic ELF magic)
      # and ship a handler desktop entry — the one bundled with appimage-run
      # declares no %F, so it cannot receive the clicked file.
      (pkgs.runCommand "appimage-mime" { } ''
        install -Dm644 ${pkgs.writeText "appimage.xml" ''
          <?xml version="1.0" encoding="UTF-8"?>
          <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
            <mime-type type="application/vnd.appimage">
              <comment>AppImage application</comment>
              <glob pattern="*.AppImage" weight="90"/>
              <glob pattern="*.appimage" weight="90"/>
            </mime-type>
          </mime-info>
        ''} $out/share/mime/packages/appimage.xml

        install -Dm644 ${pkgs.writeText "appimage-handler.desktop" ''
          [Desktop Entry]
          Categories=Utility;
          Comment=Run an AppImage with appimage-run
          Exec=appimage-run %F
          Icon=application-x-executable
          MimeType=application/vnd.appimage;
          Name=AppImage
          Terminal=false
          Type=Application
          Version=1.5
        ''} $out/share/applications/appimage-handler.desktop
      '')
      keepassxc
      telegram-desktop
      zoom-us
      equibop
      yubioath-flutter
      obsidian
      upscayl
      (bottles.override {
        removeWarningPopup = true;
        extraPkgs = pkgs: [ pkgs.vulkan-tools ];
      })
      vulkan-tools
      unrar
      # Plain runner — deliberately no extra FHS packages (no webkit chain):
      # only AppImages whose libs the base env provides will run.
      appimage-run
      kdePackages.kcalc
      foliate
    ];

    xdg.mime = {
      enable = true;
      defaultApplications = {
        "application/x-digital" = "digital.desktop";
        "text/x-digital" = "digital.desktop";
        "application/vnd.appimage" = "appimage-handler.desktop";
        "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";
      };
      addedAssociations = {
        "application/x-digital" = "digital.desktop";
        "text/x-digital" = "digital.desktop";
        "application/vnd.appimage" = "appimage-handler.desktop";
        "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";
      };
    };

    home-manager.sharedModules = [
      {
        xdg.configFile."autostart/equibop.desktop" = {
          force = true;
          text = ''
            [Desktop Entry]
            Type=Application
            Name=Equibop
            Comment=Equibop autostart script
            Exec=equibop --start-minimized
            StartupNotify=false
            Terminal=false
            Icon=equibop
          '';
        };
      }
    ];
  };
}
