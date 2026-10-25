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
                  edit = "allow";
                  bash = "allow";
                  websearch = "allow";
                  webfetch = "allow";
                  "brave-search_*" = "allow";
                  "brave_*" = "allow";
                };
                mcp = {
                  nixos = {
                    type = "local";
                    command = "mcp-nixos";
                    enabled = true;
                  };
                  brave-search = {
                    type = "local";
                    command = "npx";
                    args = [
                      "-y"
                      "@modelcontextprotocol/server-brave-search"
                    ];
                    environment = {
                      BRAVE_API_KEY = "{file:/run/secrets/brave_api_key}";
                    };
                    enabled = true;
                  };
                };
              };
            };

            # Aider-style whitespace & indentation tolerant edit plugin
            home.file."${config.xdg.configHome}/opencode/plugins/fuzzy-edit/index.js".text = ''
              import fs from "node:fs/promises";
              import path from "node:path";

              export default {
                id: "fuzzy-edit",
                setup: async () => {
                  return {
                    "tool.execute.before": async (input, output) => {
                      if (input.tool !== "edit" || !output.args?.oldString) return;

                      const { path: filePath, oldString, newString } = output.args;
                      const fullPath = path.isAbsolute(filePath)
                        ? filePath
                        : path.join(process.cwd(), filePath);

                      let content;
                      try {
                        content = await fs.readFile(fullPath, "utf8");
                      } catch {
                        return;
                      }

                      // If exact match succeeds, nothing to do
                      if (content.includes(oldString)) return;

                      // Line-trimmed matching (Aider-style relative indentation)
                      const fileLines = content.split("\n");
                      const targetLines = oldString.split("\n").map((l) => l.trim());

                      for (let i = 0; i <= fileLines.length - targetLines.length; i++) {
                        let match = true;
                        for (let j = 0; j < targetLines.length; j++) {
                          if (fileLines[i + j].trim() !== targetLines[j]) {
                            match = false;
                            break;
                          }
                        }

                        if (match) {
                          const exactOldLines = fileLines.slice(i, i + targetLines.length);
                          const exactOldString = exactOldLines.join("\n");

                          const actualIndent = exactOldLines[0].match(/^\s*/)[0];
                          const modelIndent = oldString.split("\n")[0].match(/^\s*/)[0];

                          let adjustedNewString = newString;
                          if (modelIndent !== actualIndent) {
                            adjustedNewString = newString
                              .split("\n")
                              .map((line) => {
                                if (line.startsWith(modelIndent)) {
                                  return actualIndent + line.slice(modelIndent.length);
                                }
                                return line;
                              })
                              .join("\n");
                          }

                          output.args.oldString = exactOldString;
                          output.args.newString = adjustedNewString;
                          break;
                        }
                      }
                    },
                  };
                },
              };
            '';
          }
        )
      ];
    };
}
