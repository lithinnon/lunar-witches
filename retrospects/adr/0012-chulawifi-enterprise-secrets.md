# ADR 0012: Enterprise 802.1x Authentication & Campus Wi-Fi (`ChulaWiFi`)

> **Status:** Accepted  
> **Date:** 2026-10-06  
> **Scope:** Networking, Enterprise 802.1x & Secrets Boundary  

---

## 1. Context & Problem

Chulalongkorn University's enterprise Wi-Fi networks (`ChulaWiFi`, `eduroam`) utilize 802.1x PEAP-MSCHAPv2 authentication against legacy RADIUS servers.
1. **OpenSSL 3 Security Level:** Modern Linux distros enforce OpenSSL `SECLEVEL=2` by default, rejecting legacy ciphers and TLS 1.0 handshakes used by campus RADIUS endpoints, misreporting connection failures as bad credentials.
2. **Phase 1 Outer Auth:** Modern `wpa_supplicant` disables TLS 1.0 by default in outer authentication unless `phase1-auth-flags = 32` (`0x20` = `tls-1-0-enable`) is explicitly passed.
3. **Secrets Leakage Risk:** Plain-text passwords must never be stored in `/nix/store` or Git history.
4. **NetworkManager Keyfile Escaping Quirk:** NetworkManager keyfiles require backslashes `\` in passwords to be escaped as `\\`. However, `envsubst` writes passwords unescaped, and systemd's `EnvironmentFile=` silently collapses `\\` back to `\`. As a result, passwords containing backslashes failed authentication with `keyfile: 802-1x.password: invalid setting … cannot be interpreted`.
5. **Antenna Contention:** The Realtek RTL8852CE combo card shares physical antennas between Wi-Fi and Bluetooth. 802.11 power saving causes probe scans that starve Bluetooth audio streams.

## 2. Decision

1. **Adoption of Upstream `chula-flake`:**
   - Profile generation is delegated to `inputs.chula.nixosModules.wifi`, which supplies pinned RADIUS CA certificates, declarative profiles, and `ensureProfiles.environmentFiles` credential substitution.
2. **Bare Import-Time Trait (`feature-chulawifi`):**
   - `modules/features/chulawifi.nix` layers the remaining essential quirks:
     - `phase1-auth-flags = 32` on outer PEAP authentication.
     - `openssl-ciphers = "DEFAULT@SECLEVEL=0"`.
3. **Escaping Post-Processor:**
   - An activation script post-escapes `password=` lines in `/run/NetworkManager/system-connections/` (tmpfs in RAM with 0600 permissions) and reloads NM connections (`nmcli connection reload`).
4. **Radio Power Save Policy:**
   - Dynamic Wi-Fi power save is disabled (`networking.networkmanager.wifi.powersave = false` and kernel option `rtw89_core disable_ps_mode=y`) to prevent Bluetooth audio stutter.

## 3. Consequences

- Stable enterprise 802.1x connectivity across reboots.
- Complete security isolation: credentials remain exclusively in RAM (`/run/NetworkManager/`) with 0600 permissions.
- Bluetooth and Wi-Fi operate concurrently without antenna packet starvation.
