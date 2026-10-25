# User profile module: nnon
{ inputs, ... }:

{
  flake.nixosModules.user-nnon =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.users.nnon = {
        gitSigningKey = lib.mkOption {
          type = lib.types.str;
          default = "9106CA7732D04633";
          description = "GPG signing key ID for user nnon.";
        };

        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvk/9JeTPOjRQqe3FPz0fluRQ4OvXfCwARekR0po3QI DESKTOP-E3G9LEN"
          ];
          description = "SSH authorized public keys for user nnon.";
        };
      };

      config = {
        users.users.nnon = {
          isNormalUser = true;
          description = "nnon";
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
