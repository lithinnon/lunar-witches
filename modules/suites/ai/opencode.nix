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
              extraPackages = [ pkgs.nodejs ];

              settings = {
                username = "nnon";
                snapshots = true;
                formatter = true;
                model = "llama-swap/reasoning/qwen3.8-26b-a4b";

                instructions = [
                  "${./opencode/instructions.md}"
                ];

                agent = {
                  title = {
                    disable = true;
                  };
                };

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
                          output = 32768;
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
                  execute = "deny";
                  "opencode_*" = "deny";
                  edit = "allow";
                  bash = "allow";
                  read = "allow";
                  write = "allow";
                  grep = "allow";
                  glob = "allow";
                  websearch = "allow";
                  webfetch = "allow";
                  "brave-search_*" = "allow";
                  "brave_*" = "allow";
                  set_session_title = "allow";
                };

                mcp = {
                  nixos = {
                    type = "local";
                    command = [
                      "${pkgs.mcp-nixos}/bin/mcp-nixos"
                    ];
                    enabled = true;
                    codemode = false;
                  };
                  brave-search = {
                    type = "local";
                    command = [
                      "${pkgs.nodejs}/bin/npx"
                      "-y"
                      "@modelcontextprotocol/server-brave-search"
                    ];
                    environment = {
                      BRAVE_API_KEY = "{file:/run/secrets/brave_api_key}";
                    };
                    enabled = true;
                    codemode = false;
                  };
                };
              };
            };

            # Aider-style whitespace, typo-tolerant & cognitive guard plugin
            home.file."${config.xdg.configHome}/opencode/plugins/fuzzy-edit.js".source =
              ./opencode/plugins/fuzzy-edit.js;

            # Native in-band session title tool (zero background LLM concurrency & preserves KV cache)
            home.file."${config.xdg.configHome}/opencode/plugins/session-title.js".source =
              ./opencode/plugins/session-title.js;
          }
        )
      ];
    };
}
