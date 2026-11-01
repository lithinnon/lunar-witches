# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-10-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Claude Code (Opus 5.5)
- **Timestamp:** 2026-11-01 21:40 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `e53f928`
- **Live Generation:** Generation 219 running; Generation 220 (drops `efi_pstore`) set for next boot

---

## 2. In-Flight Focus

- [ ] Watch the s2idle workaround in daily use, including long sleeps (6 good sleeps so far). Root cause unknown; patch target `rtsx_pci_resume`, `drivers/misc/cardreader/rtsx_pcr.c`. SD busy on first sleep can still hang. After a hang, full power cycle and check touchpad `ASCF1206`.
- [ ] Measure the VRR battery gain: fresh boot, no sleeps, compare `power_now` Always vs Never (11.7 W idle awake with Never; IPS RCG entries stay 0 with Always). Never toggle VRR after a sleep: it froze the display (`Pageflip timed out`; kernel alive).
- [ ] Unexplained, non-blocking: one instant `EBUSY` (`-16`) per lid sleep before a successful retry, source unknown; occasional shallow sleeps with 0% residency.
- [ ] Test tools: `~/s2idle-test/run.sh` (self-timed) and `watch.sh` (lid); run as root in system slice via `systemd-run`; logs in `~/s2idle-test/logs/`. `amd-s2idle` bypasses logind, so no hook or lock.

---

## 3. Recent Milestones

95. **Gamedev Suite, Privacy Isolation & Spirit World Integration (`eb77839`):**
    - Added `godot_4` and `gdtoolkit_4`; isolated `retrospects` into dedicated branch and worktree.
    - Integrated companion submodule `spirit-world` (`lithinnon/spirit-world`); purged secrets.
    - Socket-activated Open WebUI on port 11111 with 10m idle auto-stop; added dual-closure pre-commit.
96. **Package Hash Upstream Audit & Submodule Sync (`HEAD`):**
    - Audited fixed hashes across all in-tree packages (`rocm-therock`, `xrt-amdxdna`, `hrx-runtime`, `hrx-loom`, `radeon-developer-tool-suite`, `digital-egro`); verified all up-to-date.
    - Bump spirit world.
    - Verified dual-closure full-graph system convergence (`lunar-qualia` and `lunar-qualia-standalone`).
97. **S2idle Resume Hang Workaround with IPS On (`e53f928`, ADR 0018):**
    - Traced the wake freeze to `rtsx_pci` via `pm_trace`; hook keeps the driver out of the first real S0i3 of each boot.
    - Removed `disableDcIps` (`0x800` never reached S0i3); flashed BIOS 308. T17 and T18 (lid): 3/3 each with 10-33s S0i3.
    - Post-sleep stutter gone with VRR Never on `eDP-1`, persisted in `~/.config/kwinoutputconfig.json`, not in repo.
