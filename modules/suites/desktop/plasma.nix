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
          wayland.enable = true;
          extraPackages = with pkgs.kdePackages; [
            qtimageformats
          ];
        };
        services.desktopManager.plasma6.enable = true;
        programs.kde-pim.enable = false;

        # Headless Baloo File Indexer: prevent QGuiApplication aborts when running in background user service
        systemd.user.services.kde-baloo = {
          serviceConfig = {
            Environment = [ "QT_QPA_PLATFORM=offscreen" ];
          };
        };

        # KDE Wallet Integration (Seamless Chromium/Brave password decryption)
        security.pam.services.sddm.kwallet = {
          enable = true;
          forceRun = true;
        };
        security.pam.services.login.kwallet.enable = true;

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
