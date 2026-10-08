# Capability suite: Local LLM prose stack — SillyTavern + llama.cpp (Vulkan)
#
# SillyTavern is the frontend; llama-cpp-vulkan serves GGUF models over an
# OpenAI-compatible API on the Strix Halo iGPU (RADV already provided by
# hw-gpu-amd — no extra driver wiring). Packages only: nothing runs in the
# background, start both on demand.
#
# Typical session:
#   llama-server -m <model.gguf> -ngl 99 --port 8081   # Vulkan offload
#   sillytavern                                          # point it at :8081
# (both default to port 8080, hence the explicit --port above)
{ ... }:

{
  flake.nixosModules.suite-ai-prose = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.sillytavern
      pkgs.llama-cpp-vulkan
    ];
  };
}
