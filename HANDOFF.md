# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-13 19:44 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `0fd1f87` (fix(ssh): resolve empty SSH_ASKPASS exec failure via ksshaskpass)
- **Working Tree:** Clean
- **Live NixOS Generation:** Generation 116 (Activated; 32.0 GiB closure, 2,823 store paths)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `30dbfe1b-a3e7-4125-bf93-699888b8302a` (current), Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`, Pi `01a10a7f-7d9a-753c-9b68-372aa214bb10`, Antigravity `463892eb-7168-495e-bac8-3611a3078d13`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Fixed empty `SSH_ASKPASS` exec failure and switched to Generation 116.
- [x] Fixed OpenSSH `SSH_ASKPASS` empty string execution bug (`modules/suites/desktop/plasma.nix`, `modules/users/nnon/shell.nix`): enabled `programs.ssh.enableAskPassword = true;`, pointed `askPassword` to `/run/current-system/sw/bin/ksshaskpass`, and declared `home.sessionVariables.SSH_ASKPASS`. Activated Generation 116.
- [x] Boulesis `llama-swap` tuning (`modules/suites/ai/prose.nix`, `023deae`): reasoning loop guards and sampling set; live since Gen 112.
- [x] Declared `pkgs.skills` in `home.packages` (`modules/users/nnon/development.nix`, `206c2e3`); activated Generation 115.

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

32. **Routine Flake Inputs Update (`flake.lock`):**
    - Bumped `nixpkgs` (2026-10-08 -> 2026-10-10), `home-manager`, `antigravity-nix`, `bedrock-on-linux`.
    - Activated Generation 109 (+10.6 MiB net diff; KDE Gear 26.08.2, Brave 1.97, Obsidian 1.14, Telegram 7.2.9).
33. **Integrated ArtCraft Apps (`nix-craftapps`, `suite-desktop-apps`):**
    - Added `olafkfreund/nix-craftapps` flake input, configured PhotoCraft, FilmCraft, PdfCraft with `linkFonts = true`.
34. **Committed Boulesis Reasoning & Sampling Tuning (`023deae`, `modules/suites/ai/prose.nix`):**
    - Reasoning guards and sampling set configured in `llama-swap`; live since Generation 112.
35. **Declared `skills` CLI (`206c2e3`, `modules/users/nnon/development.nix`):**
    - `pkgs.skills` (vercel-labs/skills 1.7.1) in `home.packages`; activated Generation 115.
36. **Resolved OpenSSH Empty `SSH_ASKPASS` Bug (`plasma.nix`, `shell.nix`):**
    - Enabled `programs.ssh.enableAskPassword = true;` and set `SSH_ASKPASS = "/run/current-system/sw/bin/ksshaskpass"`.
    - Fixed `ssh_askpass: exec(): No such file or directory` failure on encrypted SSH keys.
    - Activated Generation 116.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
