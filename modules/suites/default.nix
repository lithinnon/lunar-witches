# Capability suites aggregator
{ ... }:

{
  imports = [
    ./desktop/plasma.nix
    ./desktop/audio.nix
    ./desktop/fonts.nix
    ./desktop/apps.nix
    ./desktop/service-deck.nix
    ./education/kafae.nix
    ./gaming/default.nix
    ./ai/rocm.nix
    ./ai/claude.nix
    ./ai/antigravity.nix
    ./ai/local.nix
    ./ai/prose.nix
    ./ai/open-webui.nix
    ./ai/hermes.nix
    ./development/default.nix
    ./development/gamedev.nix
  ];
}
