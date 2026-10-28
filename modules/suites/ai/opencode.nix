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
              # Patch upstream OpenCode fish completion bug (stray trailing 'c' on line 355)
              package = lib.mkDefault (
                pkgs.symlinkJoin {
                  name = "opencode-${pkgs.opencode.version}";
                  paths = [ pkgs.opencode ];
                  meta = pkgs.opencode.meta // {
                    mainProgram = "opencode";
                  };
                  postBuild = ''
                    rm "$out/share/fish/vendor_completions.d/opencode.fish"
                    mkdir -p "$out/share/fish/vendor_completions.d"
                    sed '$ { /^c$/d; }' "${pkgs.opencode}/share/fish/vendor_completions.d/opencode.fish" > "$out/share/fish/vendor_completions.d/opencode.fish"
                  '';
                }
              );
              extraPackages = [ pkgs.nodejs ];

              settings = {
                username = "nnon";
                snapshots = true;
                formatter = true;
                model = "llama-swap/reasoning/qwen3.8-26b-a4b";

                instructions = [
                  "${config.home.homeDirectory}/.agents/models/Qwen3.8-26B-A4B.md"
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
                          output = 4096;
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

            # Upstream OpenCode completion bug: strip trailing stray 'c' command from fish completions
            home.file."${config.xdg.configHome}/fish/completions/opencode.fish".text =
              builtins.replaceStrings
                [ "-l no-remote -d 'Disable remote'\nc" ]
                [ "-l no-remote -d 'Disable remote'" ]
                (builtins.readFile "${pkgs.opencode}/share/fish/vendor_completions.d/opencode.fish");
          }
        )
      ];
    };
}
