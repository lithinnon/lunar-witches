# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-11-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-11-12 13:42 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `b804b66`
- **Live Generation:** Generation 272

---

## 2. In-Flight Focus

- [ ] Watch s2idle fix (`~/s2idle-test/{run,watch}.sh` via root `systemd-run`); check `cached subsystem IDs` after BIOS updates and occasional `EBUSY` (`-16`) / 0% shallow sleeps.
- [ ] VRR culprit unproven: T21 fresh boot `Automatic` on `eDP-1` before sleep (check RCG, sleeps, game); T22 `drm.debug=0x2` + KWin CSV. Never toggle VRR after sleep.
- [ ] Complete Step D cleanup and uncheck KeePassXC startup NMH overwrite (Gen 268 live).
- [ ] Phase 2 Impermanence (`feat/impermanence`): confirm rollout scope (Stage A `@` first vs Full), `.config` persistence, large caches (`uv`/`triellama.cpp`/`ProtonPlus`), and initrd `emergencyAccess`.

---

## 3. Recent Milestones

108. **Phase 1 Declarative Suites, Host Configs & Relog Fixes (`c8c5476`):**
    - Declarative `asusd`, `th_TH.UTF-8`, `mutableUsers` password guards, `nix-flatpak`, `brave` policies, `hytale-launcher`, `acg-config-sync`, `equibop` autostart, and `protonplus` timer.
    - Hardened `pi` (`PI_OFFLINE=1` + offline `pi-extensions`), `claude-code` HM config, RO `sillytavern` extensions, and `plasma-kwin_wayland` / `app-.service` relog drop-ins.
    - Bumped spirit world; Generation 266 live and `c8c5476` built cleanly via `nh os build`.
109. **Chula Flake Native SOPS Integration (`f789732`):**
    - Replaced manual template generation with native upstream `chula.wifi.sops.enable = true`.
    - Remapped `chula-wifi/{identity,password}` secret keys to preserve existing encrypted credentials.
    - Bumped spirit world; switched system to Generation 268 via `nh os switch`.
110. **ASUS Power State Coordinator & SD Card Runtime PM Fix (`b804b66`):**
    - Refactored `sync-power-state` into `pkgs/asus-power-sync` and wired native systemd/udev trigger in `hw-oem-asus-laptop`.
    - Added dynamic Realtek RTS525A PCIe runtime PM coordination (`on` on AC, `auto` on battery) to stop `-110` resume timeouts.
    - Purged PowerDevil `RunScript` ProfileLoadCommand hooks and dropped world-writable `0666` sysfs tmpfiles; Generation 272 live.
