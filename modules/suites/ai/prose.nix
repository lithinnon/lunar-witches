# Capability suite: Local LLM prose stack — SillyTavern web interface
#
# SillyTavern runs as a systemd user unit (sillytavern.service — user scope,
# state in ~/.local/share/SillyTavern, session autostart). Toggled from the "AI"
# service-deck group.
#
# Inference models are served separately by `suite-ai-local` (llama-swap at
# 127.0.0.1:8080). SillyTavern (127.0.0.1:8234) points at the proxy for inference.
#
# This machine's config (see configFile below), all derived from the package's
# own default config:
#   * listen on 0.0.0.0:8234        (config `listen`; port set below)
#   * no browser launch on startup  (browserLaunch.enabled: false)
#   * whitelist disabled            (whitelistMode: false)
#   * multi-user accounts enabled   (enableUserAccounts: true) — the auth layer
#   * server plugins enabled        (enableServerPlugins: true)
# Port 8234 is opened on the host firewall so the listen is reachable from
# the LAN (remove networking.firewall entry if that is not wanted).
{ ... }:

{
  flake.nixosModules.suite-ai-prose =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.suites.ai.prose;
    in
    {
      options.suites.ai.prose = {
        enable = lib.mkEnableOption "Local LLM prose stack (SillyTavern web interface)" // {
          default = true;
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8234;
          description = "Port on which SillyTavern listens.";
        };

        listen = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to listen on all network interfaces (0.0.0.0).";
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to open the firewall port for SillyTavern.";
        };

        configFile = lib.mkOption {
          type = lib.types.path;
          default = pkgs.runCommand "sillytavern-config.yaml" { } ''
            sed \
              -e 's/^listen: false$/listen: true/' \
              -e 's/^whitelistMode: true$/whitelistMode: false/' \
              -e 's/^enableUserAccounts: false$/enableUserAccounts: true/' \
              -e 's/^enableServerPlugins: false$/enableServerPlugins: true/' \
              -e '/^browserLaunch:/,/^# Server port/ s/^  enabled: true$/  enabled: false/' \
              ${pkgs.sillytavern}/lib/node_modules/sillytavern/default/config.yaml > $out

            for want in 'listen: true' 'whitelistMode: false' 'enableUserAccounts: true' 'enableServerPlugins: true'; do
              grep -qx "$want" $out || { echo "sillytavern config drift: '$want' not applied"; exit 1; }
            done
            sed -n '/^browserLaunch:/,/^# Server port/p' $out | grep -q '^  enabled: false$' \
              || { echo "sillytavern config drift: browserLaunch.enabled not disabled"; exit 1; }
          '';
          description = "Derived config.yaml for SillyTavern.";
        };
      };

      config = lib.mkIf cfg.enable {
        # Explicitly disable upstream NixOS system service to prevent duplicate run
        services.sillytavern.enable = lib.mkForce false;

        environment.systemPackages = [
          pkgs.sillytavern
        ];

        # Reachability for listen=0.0.0.0 — derived from the service port
        networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

        home-manager.sharedModules = [
          {
            # Symlink the declarative config into ~/.local/share/SillyTavern/config.yaml
            xdg.dataFile."SillyTavern/config.yaml".source = cfg.configFile;

            systemd.user.services.sillytavern = {
              Unit = {
                Description = "SillyTavern — LLM Frontend (User Service)";
                After = [ "network.target" ];
              };
              Service = {
                Type = "simple";
                ExecStart = "${pkgs.sillytavern}/bin/sillytavern --port=${toString cfg.port}${lib.optionalString cfg.listen " --listen"}";
                Restart = "always";
                RestartSec = 2;
                # SillyTavern extension manager requires gitMinimal
                Environment = [
                  "PATH=${lib.makeBinPath [ pkgs.gitMinimal ]}:/run/current-system/sw/bin"
                ];
                # Third-party extensions directory bind-mounted into SillyTavern package path
                BindPaths = [
                  "-%h/.local/share/SillyTavern/extensions:${pkgs.sillytavern}/lib/node_modules/sillytavern/public/scripts/extensions/third-party"
                ];
              };
              Install = {
                WantedBy = [ "default.target" ];
              };
            };
          }
        ];
      };
    };
}
