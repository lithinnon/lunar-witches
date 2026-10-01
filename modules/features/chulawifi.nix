# Feature: Chulalongkorn University WiFi (ChulaWiFi) 802.1x Enterprise Profile
{ ... }:

{
  flake.nixosModules.feature-chulawifi =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.features.chulawifi;
      userHome =
        if cfg.user != null && config.users.users ? ${cfg.user} then
          config.users.users.${cfg.user}.home
        else
          null;
      resolvedIdentity =
        if cfg.identity != null then
          cfg.identity
        else if
          cfg.user != null && (config.users ? ${cfg.user} && config.users.${cfg.user} ? chulawifiIdentity)
        then
          config.users.${cfg.user}.chulawifiIdentity
        else
          null;
    in
    {
      options.features.chulawifi = {
        enable = lib.mkEnableOption "ChulaWiFi 802.1x enterprise connection profile";

        user = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "nnon";
          description = "User who owns this connection profile and whose home contains secrets.env.";
        };

        identity = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "6933200721";
          description = "Chula Student/Staff ID. If null, resolved via user profile or $CHULA_WIFI_IDENTITY from environmentFile.";
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = if userHome != null then "${userHome}/.config/secrets.env" else null;
          description = "Path to environment file containing CHULA_WIFI_PASSWORD / CHULA_WIFI_IDENTITY for envsubst.";
        };

        autoconnect = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to autoconnect to ChulaWiFi when in range.";
        };

        priority = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "NetworkManager connection autoconnect priority.";
        };
      };

      config = lib.mkIf cfg.enable {
        networking.networkmanager = {
          enable = true;
          ensureProfiles.profiles.ChulaWiFi = {
            connection = {
              id = "ChulaWiFi";
              type = "wifi";
              autoconnect = cfg.autoconnect;
              autoconnect-priority = cfg.priority;
            }
            // lib.optionalAttrs (cfg.user != null) {
              permissions = "user:${cfg.user}:;";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "ChulaWiFi";
            };
            wifi-security = {
              key-mgmt = "wpa-eap";
            };
            "802-1x" = {
              eap = "peap";
              phase2-auth = "mschapv2";
              identity = if resolvedIdentity != null then resolvedIdentity else "$CHULA_WIFI_IDENTITY";
              password = "$CHULA_WIFI_PASSWORD";
              # Allows legacy ciphers & TLS 1.0 handshake required by Chula's RADIUS server
              openssl-ciphers = "DEFAULT@SECLEVEL=0";
              phase1-auth-flags = 32; # 0x20 = tls-1-0-enable
            };
            ipv4 = {
              method = "auto";
              ignore-auto-dns = true;
            };
            ipv6 = {
              addr-gen-mode = "stable-privacy";
              method = "auto";
              ignore-auto-dns = true;
            };
          };
        };

        # Source environment file (supporting both 'export KEY=VAL' and 'KEY=VAL')
        # into the shell script environment before envsubst executes.
        systemd.services.NetworkManager-ensure-profiles = lib.mkIf (cfg.environmentFile != null) {
          script = lib.mkBefore ''
            if [ -f "${toString cfg.environmentFile}" ]; then
              set -a
              . "${toString cfg.environmentFile}"
              set +a
            fi
          '';
        };
      };
    };
}
