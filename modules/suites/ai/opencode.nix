# Capability suite: OpenCode (anomalyco/opencode) — Terminal AI coding agent
#
# Reaches every Home Manager user via `home-manager.sharedModules` (same
# mechanism as suite-desktop-service-deck); importing this module is the opt-in.
# Scalar knobs use lib.mkDefault so hosts/users can override them effortlessly
# (AGENTS rule 5), while list knobs stay plain so downstream entries append to
# the suite defaults instead of replacing them.
{ ... }:

{
  flake.nixosModules.suite-ai-opencode =
    { ... }:
    {
      home-manager.sharedModules = [
        (
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            programs.opencode = {
              enable = lib.mkDefault true;
              package = lib.mkDefault pkgs.opencode;

              settings = {
                model = "llama-swap/reasoning/qwen3.8-26b-a4b";
                provider = {
                  llama-swap = {
                    npm = "@ai-sdk/openai-compatible";
                    name = "llama-swap (triellama.cpp)";
                    options = {
                      baseURL = "http://127.0.0.1:8080/v1";
                      apiKey = "local";
                    };
                    models = {
                      "reasoning/qwen3.8-26b-a4b" = {
                        name = "Qwen 3.8 26B A4B (Local)";
                        limit = {
                          context = 131072;
                          output = 8192;
                        };
                      };
                      "creative/boulesis-v2.1-headtune" = {
                        name = "Boulesis v2.1 26B A4B";
                        limit = {
                          context = 65536;
                          output = 8192;
                        };
                      };
                    };
                  };
                };
                permission = {
                  edit = "allow";
                  bash = "allow";
                  websearch = "allow";
                  webfetch = "allow";
                };
                instructions = [
                  "${config.home.homeDirectory}/lunar-witches/AGENTS.md"
                ];
                skills = [
                  "${config.home.homeDirectory}/.gemini/config/skills"
                ];
                mcp = {
                  nixos = {
                    type = "local";
                    command = "mcp-nixos";
                    enabled = true;
                  };
                };
              };
            };
          }
        )
      ];
    };
}
