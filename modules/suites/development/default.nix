# Capability suite: Core Software Development & Toolchains
{ ... }:

{
  flake.nixosModules.suite-development = { pkgs, ... }: {
    # nix-ld: Run unpatched dynamic binaries (VS Code extensions, Node, Python wheels)
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

    environment.sessionVariables = {
      MESA_VK_TRACE_TRIGGER = "/tmp/mesa_vk_trace_trigger";
    };

    # Core CLI developer utilities & coding agents
    environment.systemPackages = with pkgs; [
      uv
      ghq
      ripgrep
      fd
      eza
      bat
      codex # OpenAI Codex terminal coding agent
    ];
  };
}
