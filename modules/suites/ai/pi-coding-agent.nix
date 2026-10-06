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
                defaultModel = lib.mkDefault "mimo-v2.6-flash";
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
          }
        )
      ];
    };
}
