# Capability suite: Local LLM prose stack — SillyTavern + llama.cpp (Vulkan)
#
# SillyTavern runs as the native `services.sillytavern` system unit
# (sillytavern.service — hardened sandbox, state in /var/lib/SillyTavern,
# boot autostart, localhost:8080), toggled from the "AI" service-deck group.
# llama-cpp-vulkan serves GGUF models over an OpenAI-compatible API on the
# Strix Halo iGPU (RADV via hw-gpu-amd — no extra driver wiring). Start it
# on demand:
#
#   llama-server -m <model.gguf> -ngl 99 --port 8081   # Vulkan offload
#   (SillyTavern takes :8080, hence llama-server on 8081)
{ ... }:

{
  flake.nixosModules.suite-ai-prose = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.sillytavern
      pkgs.llama-cpp-vulkan
    ];

    # Native module configured directly (AGENTS rule 5) — defaults keep the
    # dedicated "sillytavern" service user and state in /var/lib/SillyTavern.
    services.sillytavern.enable = true;
  };
}
