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
    ./ai/pi-coding-agent.nix
    ./ai/local.nix
    ./ai/prose.nix
    ./development/default.nix
  ];
}
