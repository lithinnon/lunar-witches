# Capability suite: CEDT Grader CLI / Kafae
{ inputs, ... }:

{
  flake.nixosModules.suite-education-kafae = { pkgs, ... }: {
    # Core CLI developer utilities & coding agents
    environment.systemPackages = [
      inputs.kafae.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
