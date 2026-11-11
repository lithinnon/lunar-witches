# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-11-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-11-11 12:47 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `b3b9921`
- **Live Generation:** Generation 265

---

## 2. In-Flight Focus

- [ ] Watch the s2idle fix in daily use, including lid closes and long sleeps (T20: 3/3 at 30s, `systemctl suspend`). After a BIOS update check `cached subsystem IDs` in the boot log; the hang can return if the IDs change. After a hang, full power cycle and check touchpad `ASCF1206`. Upstream patches not in master 7.3. BIOS 308 image audited: no safe firmware fix, keep the module.
- [ ] VRR, culprit unproven. Suspect: resume commit `WARN_ON` in `amdgpu_dm_handle_vrr_transition` (vblank ref not taken, wakes 1 and 3 of T17) leaves VRR active with vblank able to re-enable, giving bogus pageflip timestamps per the driver comment. Against: wake 2 had no warning, RCG stayed 0. Plan: T21 fresh boot, Automatic on `eDP-1` before first sleep, check RCG, sleeps, a game. T22 Always with `drm.debug=0x2` and KWin perf CSV for a measured stutter. Also compare `power_now`. Never toggle VRR after a sleep: it froze the display (`Pageflip timed out`; kernel alive).
- [ ] Unexplained, non-blocking: one instant `EBUSY` (`-16`) per lid sleep before a successful retry (T18), source unknown; occasional shallow sleeps with 0% residency.
- [ ] Test tools: `~/s2idle-test/run.sh` (self-timed) and `watch.sh` (lid); run as root in system slice via `systemd-run`; logs in `~/s2idle-test/logs/`. `amd-s2idle` bypasses logind, so no lock.

---

## 3. Recent Milestones

105. **YubiKey PAM U2F Sudo Integration (`3a957ad`):**
    - Configured `security.pam.u2f` with `sufficient` control and `cue = true` in `hw-peripheral-yubikey`.
    - Scoped PAM U2F specifically to `security.pam.services.sudo` to avoid interfering with SDDM/KWallet.
    - Switched system to Generation 258; installed `pam_u2f` package providing `pamu2fcfg`.
106. **SSH Git Signing, Retired GPG & Polkit U2F (`aefeaac`):**
    - Migrated Git signing from GPG to native SSH via `id_ed25519_sk.pub` and configured `allowed_signers`.
    - Prioritized hardware key in SSH client settings; retired obsolete GPG options and disabled `gpg-agent`.
    - Configured system `/etc/u2f_keys` and character device access in `polkit-agent-helper@`; switched to Gen 264.
107. **Antigravity Non-FHS Migration & nh Workflow Adoption (`b3b9921`):**
    - Switched `google-antigravity` and `google-antigravity-ide` to non-FHS variants (`autoPatchelfHook`).
    - Removed `bwrap` container and `NoNewPrivs` terminal restrictions from `AGENTS.md` and quirks doc.
    - Switched system to Generation 265 via `nh os switch`; cleaned store (7.6 GiB freed) via `nh clean all`.


