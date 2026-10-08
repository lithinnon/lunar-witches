# Capability suite: Local LLM prose stack — SillyTavern + llama.cpp (Vulkan)
#
# SillyTavern runs as the native `services.sillytavern` system unit
# (sillytavern.service — hardened sandbox, state in /var/lib/SillyTavern,
# boot autostart). Toggled from the "AI" service-deck group.
#
# This machine's config (see configFile below), all derived from the package's
# own default config:
#   * listen on 0.0.0.0:8000        (config `listen`, default address 0.0.0.0)
#   * no browser launch on startup  (browserLaunch.enabled: false)
#   * whitelist disabled            (whitelistMode: false)
#   * multi-user accounts enabled   (enableUserAccounts: true) — the auth layer
#   * server plugins enabled        (enableServerPlugins: true)
# Port 8000 is opened on the host firewall so the listen is reachable from
# the LAN (remove networking.firewall entry if that is not wanted).
#
# llama-cpp-vulkan serves GGUF models over an OpenAI-compatible API on the
# Strix Halo iGPU (RADV via hw-gpu-amd). Its default :8080 coexists with
# SillyTavern's :8000 — start on demand:
#
#   llama-server -m <model.gguf> -ngl 99
{ ... }:

{
  flake.nixosModules.suite-ai-prose = { lib, pkgs, ... }: {
    environment.systemPackages = [
      pkgs.sillytavern
      pkgs.llama-cpp-vulkan
    ];

    # Native module configured directly (AGENTS rule 5) — defaults keep the
    # dedicated "sillytavern" service user and state in /var/lib/SillyTavern.
    services.sillytavern = {
      enable = true;

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

    # Reachability for listen=0.0.0.0 (the config's port: 8000; keep in sync).
    networking.firewall.allowedTCPPorts = [ 8000 ];
  };
}
