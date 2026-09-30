# User-level Home Manager profile for nnon
{ config, pkgs, inputs, ... }:

{
  home.username = "nnon";
  home.homeDirectory = "/home/nnon";

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Shell Aliases for all shells
  home.shellAliases = {
    amdgpu-reset = "sudo -A cat /sys/kernel/debug/dri/1/amdgpu_gpu_recover";
    mesa-vk-trace = "touch /tmp/mesa_vk_trace_trigger";

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
    protonplus
    telegram-desktop
    localsend
    zoom-us
    yubioath-flutter
    equibop

    # Antigravity Suite (Antigravity 2.0 & CLI via jacopone/antigravity-nix)
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli

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

  # Declarative Git Configuration
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "lithinnon";
        email = "49898465+lithinnon@users.noreply.github.com";
      };
      init.defaultBranch = "master";
      safe.directory = "*";
    };
  };

  # Let Home Manager manage its own installation
  programs.home-manager.enable = true;

  home.stateVersion = "26.05";
}
