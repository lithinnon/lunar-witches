# Feature: Chulalongkorn University WiFi (ChulaWiFi & eduroam) 802.1x
# Thin trait over github:MiniHarinn/chula-flake — importing this module is the
# opt-in; the leaf manifest supplies `chula.wifi.environmentFile`.
{ inputs, ... }:

{
  flake.nixosModules.feature-chulawifi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.chula.nixosModules.wifi ];

      networking.networkmanager.enable = lib.mkDefault true;
      chula.wifi.enable = lib.mkDefault true;

      # Quirk 1: wpa_supplicant disables TLS 1.0 in phase 1 by default, but
      # Chula's RADIUS requires it (0x20 = tls-1-0-enable).
      networking.networkmanager.ensureProfiles.profiles =
        lib.genAttrs [ "chula-wifi" "chula-eduroam" ]
          (_: {
            "802-1x".phase1-auth-flags = 32;
          });

      # Quirk 2: NM keyfiles require backslashes in values to be escaped as
      # '\\', but envsubst writes the password raw — NM then rejects it
      # ("keyfile: 802-1x.password: invalid setting ... cannot be interpreted")
      # and 802-1x auth fails every boot (see Oct 5-6 activation failures in
      # retrospects/adr/0012-chulawifi-enterprise-secrets.md). Re-escape password values after generation and
      # reload so the on-disk profile byte-matches the known-working form.
      systemd.services.NetworkManager-ensure-profiles = lib.mkIf config.chula.wifi.enable {
        script = lib.mkAfter ''
          ${pkgs.gnused}/bin/sed -i '/^password=/ s/\\/\\\\/g' /run/NetworkManager/system-connections/chula-*.nmconnection
          ${config.networking.networkmanager.package}/bin/nmcli connection reload
        '';
      };
    };
}
