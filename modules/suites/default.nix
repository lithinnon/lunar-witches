# Capability suites aggregator
{ ... }:

{
  imports = [
    ./desktop/plasma.nix
    ./desktop/audio.nix
    ./desktop/fonts.nix
    ./desktop/apps.nix
    ./desktop/service-deck.nix
    ./gaming/default.nix
    ./ai/rocm.nix
    ./ai/antigravity.nix
    ./development/default.nix
  ];
}
