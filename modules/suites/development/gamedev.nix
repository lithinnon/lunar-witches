# Capability suite: Game Development (Godot Engine & Tooling)
{ ... }:

{
  flake.nixosModules.suite-development-gamedev = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      godot_4
      gdtoolkit_4 # gdformat, gdlint
    ];
  };
}
