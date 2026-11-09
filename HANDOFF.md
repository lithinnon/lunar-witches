# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-11-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-11-09 20:23 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `4c98ad0`
- **Live Generation:** Generation 257

---

## 2. In-Flight Focus

- [ ] Watch the s2idle fix in daily use, including lid closes and long sleeps (T20: 3/3 at 30s, `systemctl suspend`). After a BIOS update check `cached subsystem IDs` in the boot log; the hang can return if the IDs change. After a hang, full power cycle and check touchpad `ASCF1206`. Upstream patches not in master 7.3. BIOS 308 image audited: no safe firmware fix, keep the module.
- [ ] VRR, culprit unproven. Suspect: resume commit `WARN_ON` in `amdgpu_dm_handle_vrr_transition` (vblank ref not taken, wakes 1 and 3 of T17) leaves VRR active with vblank able to re-enable, giving bogus pageflip timestamps per the driver comment. Against: wake 2 had no warning, RCG stayed 0. Plan: T21 fresh boot, Automatic on `eDP-1` before first sleep, check RCG, sleeps, a game. T22 Always with `drm.debug=0x2` and KWin perf CSV for a measured stutter. Also compare `power_now`. Never toggle VRR after a sleep: it froze the display (`Pageflip timed out`; kernel alive).
- [ ] Unexplained, non-blocking: one instant `EBUSY` (`-16`) per lid sleep before a successful retry (T18), source unknown; occasional shallow sleeps with 0% residency.
- [ ] Test tools: `~/s2idle-test/run.sh` (self-timed) and `watch.sh` (lid); run as root in system slice via `systemd-run`; logs in `~/s2idle-test/logs/`. `amd-s2idle` bypasses logind, so no lock.

---

## 3. Recent Milestones

102. **Integrate Matt Pocock Skills & Decommission OpenCode (`db548d0`):**
    - Packaged flattened `mattpocock-skills` derivation and wired shared module across AI suites.
    - Wrapped Antigravity packages with basic password-store and `SSH_TTY=/dev/null` keyring bypass.
    - Decommissioned `suite-ai-opencode` and removed OpenCode shell aliases; bumped spirit world.
103. **Flake Inputs Optimization, Brave Migration & AAGL Caching (`8d4712b`):**
    - Updated inputs, migrated Brave to Buckley310 flake, deduplicated home-manager and flake-parts trees.
    - Set up system-wide ezkea Cachix substituter and keys; dropped aagl rust-overlay follow to achieve 100% cache hits.
    - Added anime-game-launcher alongside honkers-launcher in suite-gaming; switched to Generation 238.
104. **Pi Suite Migration, DeepSeek Harness & Rust Hook Fixes (`e017582`):**
    - Replaced Hermes suite with `suite-ai-pi` and `suite-ai-deepseek-harness`; wired mattpocock skills.
    - Patched nixpkgs cargo-setup-hook missing buildInputs for codex, primp, and chromadb.
    - Authorized automatic switch in `AGENTS.md`; bumped spirit world; switched to Generation 254.
