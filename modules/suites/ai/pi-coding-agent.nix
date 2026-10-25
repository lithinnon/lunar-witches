# Capability suite: pi-coding-agent (Earendil Pi) — AI coding agent
#
# Reaches every Home Manager user via `home-manager.sharedModules` (same
# mechanism as suite-desktop-service-deck); importing this module is the opt-in.
# Scalar knobs use lib.mkDefault so hosts/users can override them effortlessly
# (AGENTS rule 5), while list knobs stay plain so downstream entries append to
# the suite defaults instead of replacing them.
{ ... }:

{
  flake.nixosModules.suite-ai-pi-coding-agent =
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
          let
            cfg = config.programs.pi-coding-agent;
          in
          {
            programs.pi-coding-agent = {
              enable = lib.mkDefault true;
              configDir = lib.mkDefault "${config.xdg.configHome}/pi/agent";

              # Needed by pi to install npm packages (wrapProgram PATH suffix).
              extraPackages = [
                pkgs.nodejs
                pkgs.bun
              ];

              models = {
                providers = {
                  llama-swap = {
                    name = "triellama.cpp";
                    baseUrl = "http://127.0.0.1:8080/v1";
                    api = "openai-completions";
                    apiKey = "local";
                    models = [
                      {
                        id = "reasoning/qwen3.8-26b-a4b";
                        name = "Qwen 3.8 26B A4B (In-house)";
                        reasoning = true;
                        input = [ "text" ];
                        contextWindow = 131072;
                        cost = {
                          input = 0;
                          output = 0;
                          cacheRead = 0;
                          cacheWrite = 0;
                        };
                      }
                      {
                        id = "creative/boulesis-v2.1-headtune";
                        name = "Boulesis v2.1 26B A4B";
                        reasoning = true;
                        input = [ "text" ];
                        contextWindow = 65536;
                        maxTokens = 8192;
                        cost = {
                          input = 0;
                          output = 0;
                          cacheRead = 0;
                          cacheWrite = 0;
                        };
                      }
                    ];
                  };
                };
              };

              settings = {
                defaultProvider = lib.mkDefault "llama-swap";
                defaultModel = lib.mkDefault "reasoning/qwen3.8-26b-a4b";
                defaultThinkingLevel = lib.mkDefault "high";
                modelThinkingLevels = {
                  "llama-swap/reasoning/qwen3.8-26b-a4b" = "xhigh";
                };
                showCacheMissNotices = lib.mkDefault true;
                packages = [
                  "npm:pi-mcp-adapter"
                  "npm:pi-web-access"
                  "npm:pi-subagents"
                ];
                extensions = [
                  "-builtin:mcp"
                  "-builtin:llama.cpp"
                ];
              };

              appendSystem = ''
                ## Anti-Looping & Search Invariants
                - Never execute identical or alternating tool calls (e.g. repeated `read` or `grep`) with identical arguments if the previous result was empty or uninformative.
                - If a search tool (`grep`, `find`) returns 0 matches, accept that the target does NOT exist in the repository. Do not repeat the search or re-read the same file expecting different output.
                - Understand domain boundaries: application runtime settings (e.g. Pi settings `settings.json`, CLI flags, thinking levels) belong to Pi's own configuration (`~/.config/pi/agent/settings.json`) or upstream documentation, NOT to the target workspace codebase.
                - If a search is inconclusive after 1 attempt, stop searching immediately and report your findings to the user.
              '';
            };

            home.file."${cfg.configDir}/extensions/loop-breaker.ts".text = ''
              import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

              export default function (pi: ExtensionAPI) {
                const history: string[] = [];
                const WINDOW_SIZE = 6;

                pi.on("tool_call", async (event) => {
                  const signature = `''${event.toolName}:''${JSON.stringify(event.input ?? {})}`;
                  const occurrences = history.filter((sig) => sig === signature).length;

                  history.push(signature);
                  if (history.length > WINDOW_SIZE) {
                    history.shift();
                  }

                  if (occurrences >= 2) {
                    return {
                      block: true,
                      reason: `Loop breaker triggered: You have executed "''${event.toolName}" with identical arguments multiple times recently with no new findings. Repeating this action is blocked. Try a completely different approach or answer the user with your current knowledge.`,
                    };
                  }
                });

                pi.on("agent_start", async () => {
                  history.length = 0;
                });
              }
            '';

            home.activation.updatePi = lib.mkIf cfg.enable (
              lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                PI_BIN=""
                if [ -x "/etc/profiles/per-user/$USER/bin/pi" ]; then
                  PI_BIN="/etc/profiles/per-user/$USER/bin/pi"
                elif [ -x "$HOME/.nix-profile/bin/pi" ]; then
                  PI_BIN="$HOME/.nix-profile/bin/pi"
                elif command -v pi >/dev/null 2>&1; then
                  PI_BIN="$(command -v pi)"
                elif [ -x "${cfg.package}/bin/pi" ]; then
                  PI_BIN="${cfg.package}/bin/pi"
                fi

                if [ -n "$PI_BIN" ]; then
                  export PI_CODING_AGENT_DIR="${cfg.configDir}"
                  export PATH="${lib.makeBinPath cfg.extraPackages}:$PATH"
                  echo "Updating Pi Coding Agent model catalogs and extensions..."
                  $DRY_RUN_CMD "$PI_BIN" update --models || true
                  $DRY_RUN_CMD "$PI_BIN" update --extensions || true
                fi
              ''
            );
          }
        )
      ];
    };
}
