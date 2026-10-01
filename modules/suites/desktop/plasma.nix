# Capability suite: KDE Plasma 6 Desktop Environment, SDDM, Wayland
{ self, ... }:

{
  flake.nixosModules.suite-desktop-plasma = { pkgs, ... }: {
    imports = [
      self.nixosModules.suite-desktop-audio
      self.nixosModules.suite-desktop-fonts
    ];

    # Display Manager (SDDM Wayland) & Plasma 6
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;

    # KDE Wallet Integration (Seamless Chromium/Brave password decryption)
    security.pam.services.sddm.kwallet = {
      enable = true;
      forceRun = true;
    };
    security.pam.services.login.kwallet.enable = true;

    # Universal Wayland Session Flags & Client Desktop Drivers
    environment.sessionVariables = {
      SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";
      NIXOS_OZONE_WL = "1";

      # Client-side Computer Use Agent (CUA) automation driver Wayland protocol backend
      CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
    };

    # Plasma Integration Packages
    environment.systemPackages = with pkgs; [
      kdePackages.ksshaskpass
      kdePackages.libkscreen
      kdePackages.sddm-kcm
      kdePackages.plasma-browser-integration
      wl-clipboard
    ];
  };
}
