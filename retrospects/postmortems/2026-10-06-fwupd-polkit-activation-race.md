# Retrospect 04: `Activation (test) failed` — fwupd/Polkit Activation Race (Exit Code 4)

> **Date:** 2026-10-06 · **Host:** `lunar-qualia` · **NixOS:** 26.11 (Zokor), nixpkgs `494ce7f`
> **Tools:** `nh` 4.4.2, `switch-to-configuration-ng` 0.1.0 (Rust rewrite of the old Perl switcher)
> **Status:** Root-caused and documented. **No local fix** — bug class lives upstream; revisit triggers recorded in §8.

---

## 1. Summary

A routine `nh os switch` aborted with `Activation (test) failed … ExitStatus(Exited(4))`. An
immediate rerun — with **no changes in between** — succeeded. The exit code was not caused by
anything wrong in this repository or in the activation itself: the hourly randomized
`fwupd-refresh.timer` fired **99 ms** after the activation stopped `polkit.service` (routine
churn from a `nix flake update`), `fwupdmgr` could not reach PolicyKit, and
`switch-to-configuration-ng` fails the **entire switch with exit 4** if *any* unit is left in
`failed` state after the activation window — even a unit the switch never touched.

---

## 2. Symptom

```text
Error:
   0: Activation (test) failed
   1: Activating configuration (exit status ExitStatus(Exited(4)))
      stderr:
      … (Qt locale warnings, ksshaskpass parse message, perl locale warnings) …
      stopping the following units: accounts-daemon.service, polkit.service
      activating the configuration…
      starting the following units: accounts-daemon.service, polkit.service
      warning: the following units failed: fwupd-refresh.service
```

Journal counterpart (both emitted by `switch-to-configuration-ng`):

```text
Oct 06 14:37:30.296 nixos: switching to system configuration /nix/store/7yxgf62d… failed (status 4)
Oct 06 14:42:14.068 nixos: finished switching to system configuration /nix/store/7yxgf62d…
```

---

## 3. Timeline (2026-10-06, millisecond-precise from the journal)

| Time | Event |
|---|---|
| 08:50:57 | `flake.lock` updated (nixpkgs `a7868a7` → `494ce7f`, home-manager → `aa23f72`) |
| 14:35:37 | `flake.lock` rewritten again (antigravity-nix → `0b652b0`) |
| ~14:36 | `nh os switch` builds closure `7yxgf62d…` (polkit, accounts-daemon, fwupd, udev, HM all rebuilt → unit files changed) |
| 14:37:28.684 | `sudo -A … switch-to-configuration test` starts |
| 14:37:28.739–.764 | Stop phase: ModemManager, pcscd, accounts-daemon, **`polkit.service` stopped** |
| **14:37:28.863** | **`fwupd-refresh.timer` fires** (`LastTriggerUSec=14:37:28`; next `15:36:15`, hourly randomized) — **99 ms after polkit went down** |
| 14:37:29.485 | D-Bus system bus reload during activation |
| 14:37:29.925–.952 | `polkit.service` restarts (gap: 1.16 s) |
| 14:37:29.967 | `fwupdmgr: PolicyKit daemon is not available` (download had already reached 100 %) |
| 14:37:29.970 | `fwupd-refresh.service: Failed with result 'exit-code'` (status=1) |
| 14:37:30.296 | switcher scans units → `failed` found → `exit_code = 4` → nh aborts |
| 14:42:13 | Rerun, unchanged inputs: empty activation delta, `finished switching…`, exit 0 → **gen 69** |
| 14:52:49 | Third run after `modules/suites/ai/pi-coding-agent.nix` edit → **gen 70** (active) |

---

## 4. Root-cause chain (evidence per link)

1. **Unit churn is normal after a bump.** `nix flake update` → rebuilt daemons → their unit
   files differ → the stop phase stops and restarts them (including polkit). Unavoidable.
2. **Timer coincidence.** `systemctl show fwupd-refresh.timer -p LastTriggerUSec` =
   `Tue 2026-10-06 14:37:28` — the *timer*, not the switcher, started the service. Its six runs
   today (09:42, 10:38, 11:26, 12:04, 13:15, 14:37) all succeeded except the one that landed
   inside the polkit-down window.
3. **fwupd requires a live PolicyKit D-Bus name even for root.** `fwupdmgr refresh` completed
   its LVFS download, then the authorization check hit the gap → exit 1 → unit `failed`.
4. **The switcher fails on *any* failed unit, not just ones it managed.**
   `pkgs/by-name/sw/switch-to-configuration-ng/src/main.rs` (nixpkgs `494ce7f`):

   ```rust
   let new_active_units = get_active_units(&systemd)?;      // all units, after ≤90 s settle
   for (unit, unit_state) in new_active_units {
       if &unit_state.state == "failed" { failed_units.push(unit); … }
   …
   if !failed_units.is_empty() {
       eprintln!("warning: the following units failed: {}", …);
       exit_code = 4;                                        // ← the ExitStatus(Exited(4))
   }
   ```

   The switcher already tracks exactly which jobs *it* submitted (`submitted_jobs`,
   `units_to_stop/restart/start`) — but the final scan ignores that and is global. That
   scoping gap is the upstream bug.

---

## 5. Why the immediate rerun succeeded "for free"

- **Run 1 completed all real work before failing.** The failure check runs *at the end*; the
  live system was already fully transitioned by 14:37:30. Run 2's delta was empty (~1 s, no
  stop/start lines) → polkit was never stopped → no vulnerable window.
- **Leftover failures are cleared.** The switcher calls `systemd.reset_failed()` during
  activation, so run 1's stale `fwupd-refresh` failure could not disqualify run 2
  (its `Result=` is `success` today despite `ExecMainStatus=1`).
- **The timer didn't fire during run 2** (next trigger 15:36).
- The scary-looking stderr noise (§6) is emitted on *every* run but only *displayed* when the
  activation fails — that is the actual "output changed without me doing anything" trick.

**Operational takeaway:** on exit 4, rerun immediately. Run 1 has already applied the system
changes; the rerun only settles the profile. Afterwards verify
`readlink /nix/var/nix/profiles/system` matches expectations — until it does, the **live
system and the boot default diverge** (after run 1, the machine ran `7yxgf62d…` while the
profile still pointed at gen 68; a reboot in that gap would have booted the old generation).

---

## 6. Noise in the failure dump (all non-causes)

| Output | Cause | Harmless? |
|---|---|---|
| `Detected locale "C" … ANSI_X3.4-1968` / Qt advisory | `sudo -A` scrubs `LANG`, so `ksshaskpass` starts under locale `C`; Qt force-falls-back to `C.UTF-8` | yes |
| `ksshaskpass: Unable to parse phrase "[sudo] password for nnon: "` | ksshaskpass dislikes sudo's prompt format; authentication still succeeded (no `Sorry, try again` anywhere) | yes |
| `perl: warning: Setting locale failed … LC_NUMERIC = "th_TH.UTF-8"` ×2 | `pre-switch-checks` (still Perl) inherits a mixed `th_TH`/`C`/`en_US` LC_* env and falls back to `en_US.UTF-8` | yes — check completed |

---

## 7. Impact assessment

- **Config health:** none — the repository and the generated configuration were correct
  throughout. The chula keyfile quirk fix deployed in the same run is live
  (`NetworkManager-ensure-profiles` script contains the `sed`-escape + reload).
- **Real risk of this bug class:** false-positive exit 4 aborts `nh` *before* the profile
  link → half-switched state (§5) until rerun.
- **Odds:** ~1.2 s window per polkit-rebuilding activation vs. hourly randomized fwupd runs
  → roughly 1-in-3000 per such switch; expect a few hits per year, always cured by rerun.
  Any other transient (network, other polkit clients) inside an activation can trip the same
  global scan.

---

## 8. Decision & deferred follow-ups

**Decision: document only — no mitigation in this repository.** A ~0.03 % race does not earn
a config module, and no local lever is clean:

| Lever | Verdict |
|---|---|
| `ExecCondition=` probe for `org.freedesktop.PolicyKit1` on `fwupd-refresh.service` | **Accepted as the first move if it bites a second time** — skips (doesn't fail) during a polkit gap; declarative, no error masking |
| `systemd.timers.fwupd-refresh.enable = false` | Rejected — kills auto metadata refresh, too blunt |
| `SuccessExitStatus = "1"` | Rejected — masks genuine download failures |
| Upstream: scope the failed-units scan to units the switch actually submitted jobs for (`submitted_jobs`) | **The correct fix**; belongs in `switch-to-configuration-ng`. Issue drafted conceptually (§1 timeline + §4.4 source), not yet filed |

**Revisit triggers:** (a) a second exit-4 false positive within a rolling period → add the
`ExecCondition` guard; (b) activation failures becoming routine → file the upstream issue.

---

## 9. Evidence appendix (reproduction / commands used)

```bash
# What fired first — the timer, not the switcher
journalctl -b -u fwupd-refresh.service -o short-precise
systemctl show fwupd-refresh.timer -p LastTriggerUSec -p NextElapseUSec

# The failing instant: "PolicyKit daemon is not available" between polkit stop/start
journalctl -b --since "14:37:28" --until "14:37:31" -o short-precise

# Exit-code semantics (nixpkgs 494ce7f) — Rust rewrite, replaces the old .pl
rg -n 'exit_code = 4|following units failed|reset_failed' \
  /nix/store/<nixpkgs>/pkgs/by-name/sw/switch-to-configuration-ng/src/main.rs

# Every activation this day + which closure each run used
journalctl -b | rg 'switching to system configuration'

# Generations after the incident: 66,67,68 (morning cleanup) + 69 (run 2) + 70 (run 3, active)
readlink /nix/var/nix/profiles/system
```

The failing unit's own words, for posterity:

```text
Oct 06 14:37:29.967 fwupdmgr[1278380]: PolicyKit daemon is not available
Oct 06 14:37:29.970 systemd[1]: fwupd-refresh.service: Main process exited, code=exited, status=1/FAILURE
Oct 06 14:37:29.970 systemd[1]: Failed to start Refresh fwupd metadata and update motd.
```
