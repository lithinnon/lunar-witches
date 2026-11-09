# Capability suite: Pi Coding Agent (pi.dev)
{ ... }:

{
  flake.nixosModules.suite-ai-pi =
    { lib, pkgs, ... }:
    {
      home-manager.sharedModules = [
        (
          { config, osConfig, ... }:
          {
            programs.pi-coding-agent = {
              enable = true;
              package = pkgs.symlinkJoin {
                name = "pi-coding-agent-xdg-${pkgs.pi-coding-agent.version}";
                paths = [ pkgs.pi-coding-agent ];
                nativeBuildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                  wrapProgram $out/bin/pi \
                    --run 'export PI_CODING_AGENT_DIR="''${PI_CODING_AGENT_DIR:-$HOME/.config/pi/agent}"' \
                    --run 'export PI_CODING_AGENT_SESSION_DIR="''${PI_CODING_AGENT_SESSION_DIR:-$HOME/.local/state/pi/sessions}"' \
                    --run 'export CONTEXT_MODE_DIR="''${CONTEXT_MODE_DIR:-$HOME/.local/state/context-mode}"' \
                    --run 'if [ -f /run/secrets/brave_search_api_key ]; then export BRAVE_API_KEY="''${BRAVE_API_KEY:-$(cat /run/secrets/brave_search_api_key)}"; fi'
                '';
              };
              extraPackages = [
                pkgs.nodejs
                pkgs.bun
                pkgs.curl
                pkgs.git
              ];
              configDir = "${config.xdg.configHome}/pi/agent";
              mutableSettings = true;
              settings = {
                packages = [
                  "npm:pi-mcp-adapter"
                  "npm:pi-web-access"
                  "npm:pi-subagents"
                  "npm:pi-context-mode"
                ];
              };
            };

            home.sessionVariables = {
              PI_CODING_AGENT_SESSION_DIR = "${config.xdg.stateHome}/pi/sessions";
              CONTEXT_MODE_DIR = "${config.xdg.stateHome}/context-mode";
            };

            # Global Pi skills live in <configDir>/skills/
            # Symlink each skill folder individually from the shared mattpocock pool so
            # <configDir>/skills/ remains a normal writable directory for custom skills.
            xdg.configFile = builtins.listToAttrs (
              map (name: {
                name = "pi/agent/skills/${name}";
                value.source = "${osConfig.services.mattpocock-skills.pool}/skills/${name}";
              }) osConfig.services.mattpocock-skills.names
            );
          }
        )
      ];
    };
}
