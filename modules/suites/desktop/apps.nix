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
      keepassxc
      telegram-desktop
      zoom-us
      equibop
      yubioath-flutter
      obsidian
      upscayl
      bottles # Windows compatibility & container runtime for productivity apps
    ];
  };
}
