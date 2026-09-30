# Dendritic module: Core system configuration (Nix settings, maintenance, networking, security)
{ inputs, ... }:

{
  flake.nixosModules.core = { config, pkgs, ... }: {
    # Bootloader (systemd-boot for modern UEFI)
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Nix Flakes & Package Manager Tuning
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://attic.xuyh0120.win/lantian"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        ];
      };
    };

    # Yet-Another-Nix-Helper (nh) with automated cache retention
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
      flake = "/home/nnon/lunar-witches";
    };

    # nix-ld: Seamlessly run unpatched dynamic ELF binaries (Antigravity CLI, Antigravity 2.0, VS Code extensions, Python wheels)
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        zstd
        openssl
        curl
        # Electron & GUI dependencies (Antigravity 2.0 Desktop Orchestrator)
        glib
        gtk3
        pango
        cairo
        gdk-pixbuf
        atk
        at-spi2-atk
        at-spi2-core
        dbus
        libdrm
        libGL
        libxkbcommon
        mesa
        nspr
        nss
        alsa-lib
        cups
        expat
        systemd
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
      ];
    };

    # Default Shell Environment
    programs.fish.enable = true;

    # Security & Sudo AskPass Configuration
    security.sudo.extraConfig = ''
      Defaults passprompt_override,env_keep+="SUDO_ASKPASS"
    '';

    # Networking & DNS
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };

    # Flatpak support (specifically for Waterfox)
    services.flatpak.enable = true;

    # Syncthing Service (retains existing device identity and cluster pairing)
    services.syncthing = {
      enable = true;
      user = "nnon";
      dataDir = "/home/nnon/Sync";
      configDir = "/home/nnon/.local/state/syncthing";
      openDefaultPorts = true;
    };

    # LocalSend (AirDrop alternative with opened firewall port 53317)
    programs.localsend = {
      enable = true;
      openFirewall = true;
    };

    # KDE Connect (Seamless phone integration with opened ports 1714-1764)
    programs.kdeconnect.enable = true;

    # Steam with 32-bit graphics bridge, GameScope, and remote play firewall
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = true;
    };

    # System & Desktop Fonts (CJK support for Japanese/Anime titles, Nerd Fonts for terminal)
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];

    # Timezone and Localization
    time.timeZone = "Asia/Bangkok";
    i18n.defaultLocale = "en_US.UTF-8";

    # Ensure ~/.local/bin is in PATH for all users
    environment.localBinInPath = true;

    # Essential System Packages
    environment.systemPackages = with pkgs; [
      curl
      wget
      git
      neovim
      htop
      fastfetch
      pciutils
      usbutils
      nftables
      wireguard-tools
      openvpn
      python3
      yubikey-manager
      btrfs-progs
    ];

    # User Account Configuration
    users.users.nnon = {
      isNormalUser = true;
      description = "nnon";
      extraGroups = [ "wheel" "networkmanager" "video" "render" "audio" "input" ];
      shell = pkgs.fish;
    };

    system.stateVersion = "26.05";
  };
}
