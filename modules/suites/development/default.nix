# Capability suite: Core Software Development & Toolchains
{ ... }:

{
  flake.nixosModules.suite-development = { pkgs, ... }: {
    # nix-ld: Run unpatched dynamic binaries (CLI toolchains, VS Code extensions, uv wheels)
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        zstd
        xz
        openssl
        curl
        glib
        icu
        libdrm
        expat
        systemd
        fuse3
      ];
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
      typst
      tinymist
      typstyle
    ];
  };
}
