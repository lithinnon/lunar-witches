# Capability suite: Daily Desktop Utilities & Native Applications
{ pkgs, ... }:

{
  flake.nixosModules.suite-desktop-apps = { pkgs, ... }: {
    # Flatpak subsystem (for Waterfox or standalone sandbox apps)
    services.flatpak.enable = true;

    # LocalSend (AirDrop alternative with opened firewall port)
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };

    # KDE Connect phone integration
    programs.kdeconnect.enable = true;

    # High-performance hardware screen capture
    programs.gpu-screen-recorder.enable = true;

    # Native Desktop Applications & Utilities
    environment.systemPackages = with pkgs; [
      gpu-screen-recorder-gtk
      mpv
      btop

      # Daily Productivity & Communication
      brave
      digital
      keepassxc
      telegram-desktop
      zoom-us
      equibop
      yubioath-flutter
      obsidian

      # General Windows App Compatibility / Productivity Containers
      # (Maintained here rather than in gaming suite, as requested)
      bottles
    ];
  };
}
