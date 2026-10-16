# Feature: Declarative Secret Management via sops-nix
{ inputs, ... }:

{
  flake.nixosModules.feature-sops =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        defaultSopsFormat = lib.mkDefault "yaml";
        age = {
          # Use the machine's SSH host key for automatic decryption at boot
          sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
          keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
          generateKey = lib.mkDefault false;
        };
      };

      environment.systemPackages = [
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
      ];
    };
}
