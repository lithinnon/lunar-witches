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

              settings = {
                defaultProvider = lib.mkDefault "xiaomi-token-plan-sgp";
                defaultModel = lib.mkDefault "mimo-v2.6-pro";
                showCacheMissNotices = lib.mkDefault true;
                packages = [
                  "npm:pi-xiaomi-mimo-provider"
                  "npm:pi-mcp-adapter"
                  "npm:pi-web-access"
                ];
                extensions = [
                  "-builtin:mcp"
                  "-builtin:llama.cpp"
                ];
              };
            };

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
