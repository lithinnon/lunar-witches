# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-11-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-11-12 18:07 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `a22fb2c`
- **Live Generation:** Generation 277 (`g4j9z4`)

---

## 2. In-Flight Focus

- [ ] Watch s2idle fix (`~/s2idle-test/{run,watch}.sh` via root `systemd-run`); check `cached subsystem IDs` after BIOS updates and occasional `EBUSY` (`-16`) / 0% shallow sleeps.
- [ ] VRR culprit unproven: T21 fresh boot `Automatic` on `eDP-1` before sleep (check RCG, sleeps, game); T22 `drm.debug=0x2` + KWin CSV. Never toggle VRR after sleep.
- [ ] Complete Step D cleanup and uncheck KeePassXC startup NMH overwrite (Gen 268 live).
- [ ] Phase 2 Impermanence (`feat/impermanence`): confirm rollout scope (Stage A `@` first vs Full), `.config` persistence, large caches (`uv`/`triellama.cpp`/`ProtonPlus`), and initrd `emergencyAccess`.

---

## 3. Recent Milestones

110. **ASUS Power State Coordinator & SD Card Runtime PM Fix (`b804b66`):**
    - Refactored `sync-power-state` into `pkgs/asus-power-sync` and wired native systemd/udev trigger in `hw-oem-asus-laptop`.
    - Added dynamic Realtek RTS525A PCIe runtime PM coordination (`on` on AC, `auto` on battery) to stop `-110` resume timeouts.
    - Purged PowerDevil `RunScript` ProfileLoadCommand hooks and dropped world-writable `0666` sysfs tmpfiles; Generation 272 live.
111. **KeePassXC Secret Service Integration for Antigravity & VS Code (`5fa813a`):**
    - Routed `google-antigravity`, `google-antigravity-ide`, and VS Code (`argvSettings`) to `--password-store=gnome-libsecret`.
    - Purged non-functional KWallet PAM services on KDE Plasma in favor of native KeePassXC `FdoSecrets` D-Bus integration.
    - Enabled `direnv` in Home Manager; switched to Generation 273 via `nh os switch`.
112. **Bespoke Conduct Privilege Orchestration & Zero-Wakeup Touch Daemon (`a22fb2c`):**
    - Authored ADR 0019; engineered zero-wakeup Touch Coordinator in `conduct watch` (<1MB RSS, 0.00 Hz idle).
    - Added CTAPHID keepalive debouncing and HID report descriptor filtering to eliminate notification flapping.
    - Wired canonical system askpass paths natively into NixOS `programs.ssh` and `SUDO_ASKPASS`.
    - Bump spirit world; switched system to Generation 277 via `nh os switch`.
