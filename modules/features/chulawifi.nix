# Feature: Chulalongkorn University WiFi (ChulaWiFi & eduroam) 802.1x
# Thin trait over github:MiniHarinn/chula-flake — importing this module is the
# opt-in; the leaf manifest supplies `chula.wifi.environmentFile`.
{ inputs, ... }:

{
  flake.nixosModules.feature-chulawifi =
    { lib, ... }:
    {
      imports = [ inputs.chula.nixosModules.wifi ];

      networking.networkmanager.enable = lib.mkDefault true;
      chula.wifi.enable = lib.mkDefault true;

      # The one quirk upstream lacks: wpa_supplicant disables TLS 1.0 in phase 1
      # by default, but Chula's RADIUS requires it (0x20 = tls-1-0-enable).
      networking.networkmanager.ensureProfiles.profiles =
        lib.genAttrs [ "chula-wifi" "chula-eduroam" ]
          (_: {
            "802-1x".phase1-auth-flags = 32;
          });
    };
}
