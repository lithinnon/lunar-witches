# Capability suite: Daily Desktop Utilities & Native Applications
{ pkgs, ... }:

{
  flake.nixosModules.suite-desktop-apps = { pkgs, ... }: {
    services.flatpak.enable = true;

    programs.localsend = {
      enable = true;
      openFirewall = true;
    };

    programs.kdeconnect.enable = true;
    programs.gpu-screen-recorder.enable = true;

    environment.systemPackages = with pkgs; [
      gpu-screen-recorder-gtk
      mpv
      qbittorrent
      btop
      brave
      digital
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
      # FHS env gets gtk3 + webkit2gtk-4.1: appimage fails at runtime
      # without libwebkit2gtk-4.1.so.0 (same deps pkgs/app links against).
      (appimage-run.override {
        extraPkgs = p: [
          p.gtk3
          p.webkitgtk_4_1
        ];
      })
      kdePackages.kcalc
    ];

    xdg.mime = {
      enable = true;
      defaultApplications = {
        "application/x-digital" = "digital.desktop";
        "text/x-digital" = "digital.desktop";
        "application/vnd.appimage" = "appimage-handler.desktop";
      };
      addedAssociations = {
        "application/x-digital" = "digital.desktop";
        "text/x-digital" = "digital.desktop";
        "application/vnd.appimage" = "appimage-handler.desktop";
      };
    };
  };
}
