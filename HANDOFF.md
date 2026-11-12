# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-11-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-11-13 01:48 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `37e078b`
- **Live Generation:** Generation 283 (`ffwxpij`)

---

## 2. In-Flight Focus

- [ ] Watch s2idle fix (`~/s2idle-test/{run,watch}.sh` via root `systemd-run`); check `cached subsystem IDs` after BIOS updates and occasional `EBUSY` (`-16`) / 0% shallow sleeps.
- [ ] VRR culprit unproven: T21 fresh boot `Automatic` on `eDP-1` before sleep (check RCG, sleeps, game); T22 `drm.debug=0x2` + KWin CSV. Never toggle VRR after sleep.
- [ ] Complete Step D cleanup and uncheck KeePassXC startup NMH overwrite (Gen 268 live).
- [ ] Phase 2 Impermanence (`feat/impermanence`): confirm rollout scope (Stage A `@` first vs Full), `.config` persistence, large caches (`uv`/`triellama.cpp`/`ProtonPlus`), and initrd `emergencyAccess`.

---

## 3. Recent Milestones

112. **Bespoke Conduct Privilege Orchestration & Zero-Wakeup Touch Daemon (`a22fb2c`):**
    - Authored ADR 0019; engineered zero-wakeup Touch Coordinator in `conduct watch` (<1MB RSS, 0.00 Hz idle).
    - Added CTAPHID keepalive debouncing and HID report descriptor filtering to eliminate notification flapping.
    - Wired canonical system askpass paths natively into NixOS `programs.ssh` and `SUDO_ASKPASS`.
    - Bump spirit world; switched system to Generation 277 via `nh os switch`.
113. **Lunar Witches Direnv & Shell Hook Integration (`eb6a5f0`):**
    - Added `.envrc` (`use flake`), ignored `.direnv/`, and added `mkhl.direnv` to `.vscode/extensions.json`.
    - Verified `nix-direnv` devShell caching, binary availability (`nixd`, `treefmt`), and auto-hooking (`core.hooksPath`).
114. **Declarative Equibop arRPC Data Wrapper & Game Fixes (`37e078b`):**
    - Engineered `pkgs/equibop/default.nix` wrapping `equibop` to export `ARRPC_DATA_DIR` defaulting to `${XDG_CONFIG_HOME:-$HOME/.config}/equibop`.
    - Exposed standalone `packages.equibop` and overlay in `pkgs/default.nix`.
    - Declared `xdg.configFile."equibop/detectable_fixes.json"` in `modules/suites/desktop/apps.nix` with Stella Sora App ID (`1440138512451244063`) and executables (`stellasora.exe`, `StellaSora.exe`).
    - Switched system to Generation 283 (`ffwxpij`) via `nh os switch`.
