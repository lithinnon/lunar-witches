# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-11-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-11-02 10:55 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `1198798`
- **Live Generation:** Generation 221

---

## 2. In-Flight Focus

- [ ] Watch the s2idle fix in daily use, including lid closes and long sleeps (T20: 3/3 at 30s, `systemctl suspend`). After a BIOS update check `cached subsystem IDs` in the boot log; the hang can return if the IDs change. After a hang, full power cycle and check touchpad `ASCF1206`. Upstream patches not in master 7.3. BIOS 308 image audited: no safe firmware fix, keep the module.
- [ ] VRR, culprit unproven. Suspect: resume commit `WARN_ON` in `amdgpu_dm_handle_vrr_transition` (vblank ref not taken, wakes 1 and 3 of T17) leaves VRR active with vblank able to re-enable, giving bogus pageflip timestamps per the driver comment. Against: wake 2 had no warning, RCG stayed 0. Plan: T21 fresh boot, Automatic on `eDP-1` before first sleep, check RCG, sleeps, a game. T22 Always with `drm.debug=0x2` and KWin perf CSV for a measured stutter. Also compare `power_now`. Never toggle VRR after a sleep: it froze the display (`Pageflip timed out`; kernel alive).
- [ ] Unexplained, non-blocking: one instant `EBUSY` (`-16`) per lid sleep before a successful retry (T18), source unknown; occasional shallow sleeps with 0% residency.
- [ ] Test tools: `~/s2idle-test/run.sh` (self-timed) and `watch.sh` (lid); run as root in system slice via `systemd-run`; logs in `~/s2idle-test/logs/`. `amd-s2idle` bypasses logind, so no lock.

---

## 3. Recent Milestones

97. **S2idle Resume Hang Workaround with IPS On (`e53f928`, ADR 0018):**
    - Traced the wake freeze to `rtsx_pci` via `pm_trace`; hook kept the driver out of the first real S0i3 of each boot.
    - Removed `disableDcIps` (`0x800` never reached S0i3); flashed BIOS 308. T17 and T18 (lid): 3/3 each with 10-33s S0i3.
    - Post-sleep stutter gone with VRR Never on `eDP-1`, persisted in `~/.config/kwinoutputconfig.json`, not in repo.
98. **S2idle Root Cause Fixed Without Workaround (`347e27c`, ADR 0018):**
    - Firmware loses the SD reader's subsystem IDs in S0i3; `pciehp` removes it as replaced and blocks syncing the mounted card.
    - Added `pkgs/rtsx-subsystem-ids` to cache the post-S0i3 IDs at boot; removed the hook. Confirmed by T19 (card unmounted) and T20.
    - T20 (Tera mounted, no hook): 3/3 with 27-29s S0i3, no `pciehp` events, no remount.
99. **Add yt-dlp to Desktop Applications Suite (`1198798`):**
    - Declared `yt-dlp` in `modules/suites/desktop/apps.nix` (`suite-desktop-apps`).
    - Verified dual-closure full-graph convergence (`lunar-qualia` and `lunar-qualia-standalone`).
