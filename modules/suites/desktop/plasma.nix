# Capability suite: KDE Plasma 6 Desktop Environment, SDDM, Wayland
{ self, ... }:

{
  flake.nixosModules.suite-desktop-plasma =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.suite-desktop-audio
        self.nixosModules.suite-desktop-fonts
        self.nixosModules.suite-desktop-service-deck
      ];

      options.suites.desktop.plasma = {
        sddm = {
          background = lib.mkOption {
            type = with lib.types; nullOr (either path str);
            default = null;
            description = "Path to the background image for the SDDM Breeze login theme.";
          };
        };
      };

      config = {
        services.displayManager.sddm = {
          enable = true;
          autoNumlock = lib.mkDefault true;
          wayland.enable = true;
          extraPackages = with pkgs.kdePackages; [
            qtimageformats
          ];
        };
        services.desktopManager.plasma6.enable = true;
        programs.kde-pim.enable = false;

        # Ensure KDE Wayland logout tears down graphical-session.target even with linger = true
        # so D-Bus portal activations during logout cannot leave it active across relogins.
        systemd.user.services."plasma-kwin_wayland" = {
          overrideStrategy = "asDropin";
          restartIfChanged = false;
          enableDefaultPath = false;
          serviceConfig.ExecStopPost = [
            "-${config.systemd.package}/bin/systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY"
            "-${config.systemd.package}/bin/systemctl --user stop --no-block graphical-session.target"
          ];
        };

        # Belt-and-suspenders guard: keep XDG autostart apps ordered after plasma-workspace.target
        # rather than racing compositor readiness if graphical-session.target is already active.
        systemd.user.units."app-.service" = {
          overrideStrategy = "asDropin";
          text = ''
            [Unit]
            After=plasma-workspace.target
          '';
        };

        programs.ssh = {
          enableAskPassword = true;
          askPassword = "/run/current-system/sw/bin/ksshaskpass";
        };

        environment.sessionVariables = {
          SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
          NH_SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
          SSH_ASKPASS_REQUIRE = "prefer";
          NIXOS_OZONE_WL = "1";

          # Client-side Computer Use Agent (CUA) automation driver Wayland protocol backend
          CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
        };

        environment.systemPackages =
          with pkgs;
          [
            kdePackages.ksshaskpass
            kdePackages.libkscreen
            kdePackages.sddm-kcm
            kdePackages.plasma-browser-integration
            wl-clipboard
          ]
          ++ lib.optional (config.suites.desktop.plasma.sddm.background != null) (
            writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
              [General]
              background=${config.suites.desktop.plasma.sddm.background}
            ''
          );
      };
    };
}
