# User profile module: nnon
{ inputs, ... }:

{
  flake.nixosModules.user-nnon =
    {
      config,
      pkgs,
      lib,
      options,
      ...
    }:
    {
      options.users.nnon = {
        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvk/9JeTPOjRQqe3FPz0fluRQ4OvXfCwARekR0po3QI DESKTOP-E3G9LEN"
          ];
          description = "SSH authorized public keys for user nnon.";
        };
      };

      config = {
        users.mutableUsers = lib.mkIf (options ? sops && config.sops.secrets ? "nnon_password_hash") (
          lib.mkDefault false
        );

        users.users.nnon = {
          isNormalUser = true;
          description = "nnon";
          hashedPasswordFile = lib.mkIf (
            options ? sops && config.sops.secrets ? "nnon_password_hash"
          ) config.sops.secrets."nnon_password_hash".path;
          openssh.authorizedKeys.keys = config.users.nnon.authorizedKeys;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "render"
            "audio"
            "input"
          ];
          shell = pkgs.fish;
        };

        home-manager.sharedModules = [
          inputs.plasma-manager.homeModules.plasma-manager
        ];

        home-manager.users.nnon = {
          imports = [
            ./shell.nix
            ./development.nix
            ./desktop.nix
            ./plasma.nix
          ];

          xdg.enable = true;

          home.username = "nnon";
          home.homeDirectory = "/home/nnon";
          home.stateVersion = "26.05";
          programs.home-manager.enable = true;
        };
      };
    };
}
