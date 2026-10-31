# Capability suite: Google Antigravity 2.0 & CLI
{ inputs, ... }:

{
  flake.nixosModules.suite-ai-antigravity = { pkgs, ... }: {
    environment.sessionVariables = {
      AGY_CLI_HIDE_ACCOUNT_INFO = "1";
    };

    environment.systemPackages = [
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide
      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
      pkgs.mcp-nixos
    ];
  };
}
