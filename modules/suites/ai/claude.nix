# Capability suite: Claude
{ inputs, ... }:

{
  flake.nixosModules.suite-ai-claude = { pkgs, ... }: {
    home-manager.sharedModules = [
      {
        home.packages = [
          inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-fhs
          pkgs.claude-code
        ];
      }
    ];
  };
}
