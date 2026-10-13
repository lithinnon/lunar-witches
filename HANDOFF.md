# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Pi (MiMo v2.6)
- **Timestamp:** 2026-10-13 14:30 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `023deae` (boulesis tuning) — followed by this `docs(handoff)` commit
- **Working Tree:** Clean
- **Live NixOS Generation:** Generation 115 (Activated; 32.0 GiB closure, 2,822 store paths)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Pi `01a13422-d88c-70d1-a404-d738cde6a7e2` (current), Pi `01a10a7f-7d9a-753c-9b68-372aa214bb10` (archived), Antigravity `463892eb-7168-495e-bac8-3611a3078d13`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Boulesis tuning committed + `skills` CLI rollout.
- [x] Boulesis `llama-swap` tuning (`modules/suites/ai/prose.nix`, `023deae`): `--reasoning-budget 2304`, `--reasoning-loop-check-interval 32`, `--reasoning-loop-interventions 1`, plus sampling set (`--temp 1.00`, `--top-k 64`, `--repeat-penalty 1.06`, `--repeat-last-n 128`, `--dry-multiplier 0.80`, `--dry-penalty-last-n 256`). Live since Generation 112 (`llama-swap.service` restarted).
- [x] Declared `pkgs.skills` (vercel-labs/skills 1.7.1) in `home.packages` (`modules/users/nnon/development.nix`, `206c2e3`) — NixOS-patched replacement for `npx skills`; activated Generation 115.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–31):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

31. **Enabled Wire Tooltips in Digital (`modules/users/nnon/desktop.nix`):**
    - Declared `<entry><string>wireToolTips</string><boolean>true</boolean></entry>` in `home.file.".digital.cfg"`.
    - Overcame read-only nix store symlink limitation in Home Manager.
32. **Routine Flake Inputs Update (`flake.lock`):**
    - Bumped `nixpkgs` (2026-10-08 -> 2026-10-10), `home-manager`, `antigravity-nix`, `bedrock-on-linux`.
    - Activated Generation 109 (+10.6 MiB net diff; KDE Gear 26.08.2, Brave 1.97, Obsidian 1.14, Telegram 7.2.9).
33. **Integrated ArtCraft Apps (`nix-craftapps`, `suite-desktop-apps`):**
    - Added `olafkfreund/nix-craftapps` flake input.
    - Configured `programs.craftapps` with PhotoCraft, FilmCraft, and PdfCraft.
    - Solves `/usr/share/fonts` NixOS lookup via declarative `linkFonts = true` tmpfiles symlink.
    - Successfully built and cached candidate system closure (+365 MiB).
34. **Committed Boulesis Reasoning & Sampling Tuning (`023deae`, `modules/suites/ai/prose.nix`):**
    - Reasoning guards: `--reasoning-budget 2304`, `--reasoning-loop-check-interval 32`, `--reasoning-loop-interventions 1`.
    - Sampling set: `--temp 1.00`, `--top-k 64`, `--repeat-penalty 1.06`, `--repeat-last-n 128`, DRY `--dry-multiplier 0.80` / `--dry-penalty-last-n 256`.
    - Live since Generation 112; committed from previously-dirty Antigravity WIP.
35. **Declared `skills` CLI (`206c2e3`, `modules/users/nnon/development.nix`):**
    - `pkgs.skills` (vercel-labs/skills 1.7.1) in `home.packages` — replaces `npx skills`; no npm cache, NixOS-patched, fish completions included.
    - Activated Generation 115; binary at `/etc/profiles/per-user/nnon/bin/skills`.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
