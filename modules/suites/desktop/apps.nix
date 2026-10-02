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
          </mime-info>
        ''} $out/share/mime/packages/digital.xml

        install -Dm644 ${pkgs.writeText "digital.desktop" ''
          [Desktop Entry]
          Categories=Education;Electronics;
          Comment=Easy-to-use digital logic designer and circuit simulator
          Exec=digital %F
          Icon=digital
          Keywords=simulator;digital;circuits;
          MimeType=application/x-digital;text/x-digital;
          Name=Digital
          Terminal=false
          Type=Application
          Version=1.5
        ''} $out/share/applications/digital.desktop
      '')
      keepassxc
      telegram-desktop
      zoom-us
      equibop
      yubioath-flutter
      obsidian
      upscayl
      bottles # Windows compatibility & container runtime for productivity apps
    ];

    xdg.mime = {
      enable = true;
      defaultApplications = {
        "application/x-digital" = "digital.desktop";
        "text/x-digital" = "digital.desktop";
      };
      addedAssociations = {
        "application/x-digital" = "digital.desktop";
        "text/x-digital" = "digital.desktop";
      };
    };
  };
}
