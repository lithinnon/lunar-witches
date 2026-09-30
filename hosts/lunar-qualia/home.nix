# User-level Home Manager profile for nnon
{ config, pkgs, inputs, ... }:

{
  home.username = "nnon";
  home.homeDirectory = "/home/nnon";

  # Shell Aliases for all shells
  home.shellAliases = {
    amdgpu-reset = "sudo -A cat /sys/kernel/debug/dri/1/amdgpu_gpu_recover";
    mesa-vk-trace = "touch \${MESA_VK_TRACE_TRIGGER:-/tmp/mesa_vk_trace_trigger}";

    ".." = "cd ..";
    "..." = "cd ...";

    cls = "clear";

    vi = "nvim";
    vim = "nvim";

    g = "git";

    cp = "cp -i";
    mv = "mv -i";

    gq = "ghq get --update -p --look --parallel";

    setup-optiscaler = "chmod +x ./setup_linux.sh && ./setup_linux.sh";
  };

  # Fish Shell Configuration
  programs.fish = {
    enable = true;
    shellAliases = config.home.shellAliases;
    interactiveShellInit = ''
      # Disable fish greeting
      set -g fish_greeting
    '';
  };

  # Native User Applications (Replacing Flatpaks where available)
  home.packages = with pkgs; [
    # Core User Apps
    brave
    digital
    keepassxc
    bottles
    telegram-desktop
    localsend
    zoom-us
    yubioath-flutter
    equibop

    # Development & Tools
    ghq
    ripgrep
    fd
    eza
    bat
    obsidian
    mangohud
    uv
  ];

  # AMD GPU Boost background service (D-Bus event-driven clock manager)
  systemd.user.services.amdgpu-boost = {
    Unit = {
      Description = "AMD GPU Performance Boost & DPM Manager Daemon";
      After = [ "graphical-session.target" "asusd.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "%h/.local/bin/amdgpu-boost --daemon";
      Restart = "always";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Visual Studio Code
  programs.vscode = {
    enable = true;
  };

  # Let Home Manager manage its own installation
  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
