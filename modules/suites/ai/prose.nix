# Capability suite: Local LLM prose stack — SillyTavern + beellama.cpp (ROCm / HRX)
#
# SillyTavern runs as the native `services.sillytavern` system unit
# (sillytavern.service — hardened sandbox, state in /var/lib/SillyTavern,
# boot autostart). Toggled from the "AI" service-deck group.
#
# This machine's config (see configFile below), all derived from the package's
# own default config:
#   * listen on 0.0.0.0:8234        (config `listen`; port set below)
#   * no browser launch on startup  (browserLaunch.enabled: false)
#   * whitelist disabled            (whitelistMode: false)
#   * multi-user accounts enabled   (enableUserAccounts: true) — the auth layer
#   * server plugins enabled        (enableServerPlugins: true)
# Port 8000 is opened on the host firewall so the listen is reachable from
# the LAN (remove networking.firewall entry if that is not wanted).
#
# beellama serves GGUF models on the Strix Halo iGPU (Radeon 8060S gfx1151 via
# HRX / ROCm). The user-level llama-swap.service owns 127.0.0.1:8080,
# spawning llama-server per model on ports from 5800 up (config `${PORT}`),
# unloading via per-model ttl. Toggled from the "AI" service-deck group.
# Manual llama-server runs need --port elsewhere (or stop the service).
# SillyTavern (127.0.0.1:8234) points at the proxy for inference.
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
      # Nix value → YAML converter (pkgs.formats.yaml standard, remarshal-
      # backed): the llama-swap config below is written as a Nix attrset and
      # rendered to YAML at build time.
      llamaSwapFormat = pkgs.formats.yaml { };
    in
    {
      environment.systemPackages = [
        pkgs.sillytavern
        # HF Hub client (`hf` CLI) for pulling GGUF models and datasets
        pkgs.python314Packages.huggingface-hub
        # On-demand model swap proxy: manages llama-server instances per model
        pkgs.llama-swap
      ];

      # llama-swap config, consumed at $XDG_CONFIG_HOME/llama-swap.yml.
      # Written as a Nix attrset and rendered to YAML via pkgs.formats.yaml;
      # schema notes live as comments next to the values they describe.
      home-manager.sharedModules = [
        {
          xdg.configFile."llama-swap.yml".source = llamaSwapFormat.generate "llama-swap.yml" (
            # Schema: config-schema.json @ github.com/mostlygeek/llama-swap —
            # only `models` is required; every other top-level key has a
            # default (healthCheckTimeout=120, globalTTL=0, logLevel=info,
            # startPort=5800 for the ${PORT} macro, proxy already
            # http://localhost:${PORT}, checkEndpoint=/health).
            #   * model ID = the `model` value clients send in API requests
            #   * ttl is INTEGER SECONDS (-1 = global default, 0 = never)
            {
              models = {
                "creative/boulesis-v2.1-headtune" = {
                  ttl = 1200; # 20 minutes
                  cmd = ''
                    ${pkgs.beellama}/bin/llama-server \
                        --ctx-size 65536 \
                        --batch-size 2048 \
                        --ubatch-size 512 \
                        --flash-attn on \
                        --cache-type-k snc8 \
                        --cache-type-v snc8 \
                        --kv-tail-tokens 1024 \
                        --kv-tail-type bf16 \
                        --cache-ram 0 \
                        --cache-disk 16384 \
                        --device ROCm0 \
                        --n-gpu-layers all \
                        --hf-repo mradermacher/Boulesis-v2.1-26B-A4B-HeadTune-i1-GGUF:IQ4_XS \
                        --no-mmproj \
                        --port ''${PORT} \
                        --no-webui \
                        --cache-reuse 256 \
                        --reasoning-format deepseek \
                        --reasoning on \
                        --reasoning-budget-message " ... reasoning budget exceeded, need to answer.\n" \
                        --no-reasoning-preserve
                  '';
                };
              };
            }
          );

          # User-level proxy service. Loopback-only: SillyTavern (same host)
          # is the intended client, so the LAN never reaches model backends.
          # Spawned llama-server processes inherit the user-manager PATH
          # (llama-server lives in the system profile).
          systemd.user.services.llama-swap = {
            Unit = {
              Description = "llama-swap — on-demand model swapping proxy for llama.cpp";
            };
            Service = {
              Type = "simple";
              ExecStart = "${pkgs.llama-swap}/bin/llama-swap -config %h/.config/llama-swap.yml -listen 127.0.0.1:8080";
              Restart = "on-failure";
              RestartSec = 2;
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        }
      ];

      # Native module configured directly (AGENTS rule 5) — defaults keep the
      # dedicated "sillytavern" service user and state in /var/lib/SillyTavern.
      services.sillytavern = {
        enable = true;

        # Passed as --port on the command line, which overrides config.yaml's
        # default 8000 — single source of truth for the port (see firewall below).
        port = 8234;

        # Built from THIS package's default config on every evaluation, with the
        # five switches above flipped — new upstream keys flow in automatically
        # on upgrades, and the assertions fail the build if a pattern drifts.
        # Edit the substitutions here to change server configuration.
        configFile = lib.mkDefault "${pkgs.runCommand "sillytavern-config.yaml" { } ''
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
        ''}";
      };

      # Reachability for listen=0.0.0.0 — derived from the service port so the
      # two can never drift apart.
      networking.firewall.allowedTCPPorts = lib.optional (
        config.services.sillytavern.port != null
      ) config.services.sillytavern.port;
    };
}
