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
                          output = 16384;
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
                    command = [
                      "${pkgs.mcp-nixos}/bin/mcp-nixos"
                    ];
                    enabled = true;
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
                  };
                };
              };
            };

            # Aider-style whitespace, typo-tolerant & cognitive guard plugin
            home.file."${config.xdg.configHome}/opencode/plugins/fuzzy-edit.js".text = ''
              import fs from "node:fs/promises";
              import path from "node:path";

              function levenshtein(a, b) {
                if (a === b) return 0;
                if (a.length === 0) return b.length;
                if (b.length === 0) return a.length;
                const matrix = [];
                for (let i = 0; i <= b.length; i++) matrix[i] = [i];
                for (let j = 0; j <= a.length; j++) matrix[0][j] = j;
                for (let i = 1; i <= b.length; i++) {
                  for (let j = 1; j <= a.length; j++) {
                    if (b.charAt(i - 1) === a.charAt(j - 1)) {
                      matrix[i][j] = matrix[i - 1][j - 1];
                    } else {
                      matrix[i][j] = Math.min(
                        matrix[i - 1][j - 1] + 1,
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j] + 1
                      );
                    }
                  }
                }
                return matrix[b.length][a.length];
              }

              export default {
                id: "fuzzy-edit",
                setup: async () => {
                  return {
                    "tool.execute.before": async (input, output) => {
                      // 1. Anti-Sed Guard: Block raw sed -i calls on source files to prevent line-arithmetic corruption
                      if (input.tool === "bash") {
                        const cmd = String(output.args?.command ?? "");
                        if (
                          /\bsed\s+-[a-zA-Z]*i\b/.test(cmd) &&
                          !cmd.includes("/tmp") &&
                          !cmd.includes("/dev/null")
                        ) {
                          throw new Error(
                            "Agent-Guard: Modifying files via raw 'sed -i' is prohibited to prevent line-arithmetic corruption. Please use the 'edit' or 'write' tool instead."
                          );
                        }
                      }

                      // 2. Whitespace & Typo Tolerant Edit Tool (Aider-style relative indent + Levenshtein match)
                      if (input.tool === "edit" && output.args?.oldString) {
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

                        const fileLines = content.split("\n");
                        const targetLines = oldString.split("\n").map((l) => l.trim());

                        let matchIndex = -1;
                        let isTypoMatch = false;

                        // Pass 1: Line-trimmed match (ignores indentation discrepancies)
                        for (let i = 0; i <= fileLines.length - targetLines.length; i++) {
                          let match = true;
                          for (let j = 0; j < targetLines.length; j++) {
                            if (fileLines[i + j].trim() !== targetLines[j]) {
                              match = false;
                              break;
                            }
                          }
                          if (match) {
                            matchIndex = i;
                            break;
                          }
                        }

                        // Pass 2: Levenshtein typo match (catches perceptual slips like 'sites' vs 'suites')
                        if (matchIndex === -1 && targetLines.length > 0) {
                          for (let i = 0; i <= fileLines.length - targetLines.length; i++) {
                            let match = true;
                            for (let j = 0; j < targetLines.length; j++) {
                              const fLine = fileLines[i + j].trim();
                              const tLine = targetLines[j];
                              const maxDistance = Math.max(1, Math.floor(tLine.length * 0.15));
                              if (levenshtein(fLine, tLine) > maxDistance) {
                                match = false;
                                break;
                              }
                            }
                            if (match) {
                              matchIndex = i;
                              isTypoMatch = true;
                              break;
                            }
                          }
                        }

                        if (matchIndex !== -1) {
                          const exactOldLines = fileLines.slice(matchIndex, matchIndex + targetLines.length);
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

                          // If typo match occurred, fix occurrences of typo'd anchor in adjustedNewString
                          if (isTypoMatch) {
                            const origOldLines = oldString.split("\n");
                            for (let j = 0; j < origOldLines.length; j++) {
                              const origOld = origOldLines[j].trim();
                              const realFile = exactOldLines[j].trim();
                              if (origOld !== realFile && adjustedNewString.includes(origOld)) {
                                adjustedNewString = adjustedNewString.replaceAll(origOld, realFile);
                              }
                            }
                          }

                          output.args.oldString = exactOldString;
                          output.args.newString = adjustedNewString;
                        }
                      }
                    },

                    "tool.execute.after": async (input, output) => {
                      // 3. Negative-Proof Annotator: Halt infinite search loops when 0 matches are found
                      const cmd = String(input.args?.command ?? "");
                      const isSearch =
                        input.tool === "grep" ||
                        input.tool === "glob" ||
                        cmd.includes("grep") ||
                        cmd.includes("rg") ||
                        cmd.includes("find");

                      if (isSearch && output && output.content !== undefined) {
                        const text =
                          typeof output.content === "string"
                            ? output.content
                            : JSON.stringify(output.content ?? "");
                        if (
                          !text.trim() ||
                          text.trim() === "(no output)" ||
                          text.trim() === "[]" ||
                          text.trim() === "\"\""
                        ) {
                          output.content =
                            "(no output — 0 matches found. The target pattern does not exist in this search space. Do not repeat the same search; accept this negative proof and state your findings to the user.)";
                        }
                      }

                      // 4. Ambiguous Tool Failures & Silent Exits: Prevent assuming success on failed commands
                      if (input.tool === "bash" && output?.isError) {
                        const text =
                          typeof output.content === "string"
                            ? output.content
                            : JSON.stringify(output.content ?? "");
                        if (!text.trim() || text.trim() === "(no output)" || text.trim() === "\"\"") {
                          output.content =
                            "[CRITICAL: Command exited with a non-zero failure code and produced no output. Do not assume success.]";
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
