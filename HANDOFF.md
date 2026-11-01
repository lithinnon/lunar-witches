# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-11-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Claude Code (Opus 5.5)
- **Timestamp:** 2026-11-01 22:15 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `347e27c`
- **Live Generation:** Generation 221

---

## 2. In-Flight Focus

- [ ] Watch the s2idle fix in daily use, including lid closes and long sleeps (T20: 3/3 at 30s, `systemctl suspend`). After a BIOS update check `cached subsystem IDs` in the boot log; the hang can return if the IDs change. After a hang, full power cycle and check touchpad `ASCF1206`. Upstream patches not in master 7.3.
- [ ] Measure the VRR battery gain: fresh boot, no sleeps, compare `power_now` Always vs Never (11.7 W idle awake with Never; IPS RCG entries stay 0 with Always). Never toggle VRR after a sleep: it froze the display (`Pageflip timed out`; kernel alive).
- [ ] Unexplained, non-blocking: one instant `EBUSY` (`-16`) per lid sleep before a successful retry (T18), source unknown; occasional shallow sleeps with 0% residency.
- [ ] Test tools: `~/s2idle-test/run.sh` (self-timed) and `watch.sh` (lid); run as root in system slice via `systemd-run`; logs in `~/s2idle-test/logs/`. `amd-s2idle` bypasses logind, so no lock.

---

## 3. Recent Milestones

96. **Package Hash Upstream Audit & Submodule Sync (`HEAD`):**
    - Audited fixed hashes across all in-tree packages (`rocm-therock`, `xrt-amdxdna`, `hrx-runtime`, `hrx-loom`, `radeon-developer-tool-suite`, `digital-egro`); verified all up-to-date.
    - Bump spirit world.
    - Verified dual-closure full-graph system convergence (`lunar-qualia` and `lunar-qualia-standalone`).
97. **S2idle Resume Hang Workaround with IPS On (`e53f928`, ADR 0018):**
    - Traced the wake freeze to `rtsx_pci` via `pm_trace`; hook kept the driver out of the first real S0i3 of each boot.
    - Removed `disableDcIps` (`0x800` never reached S0i3); flashed BIOS 308. T17 and T18 (lid): 3/3 each with 10-33s S0i3.
    - Post-sleep stutter gone with VRR Never on `eDP-1`, persisted in `~/.config/kwinoutputconfig.json`, not in repo.
98. **S2idle Root Cause Fixed Without Workaround (`347e27c`, ADR 0018):**
    - Firmware loses the SD reader's subsystem IDs in S0i3; `pciehp` removes it as replaced and blocks syncing the mounted card.
    - Added `pkgs/rtsx-subsystem-ids` to cache the post-S0i3 IDs at boot; removed the hook. Confirmed by T19 (card unmounted) and T20.
    - T20 (Tera mounted, no hook): 3/3 with 27-29s S0i3, no `pciehp` events, no remount.
