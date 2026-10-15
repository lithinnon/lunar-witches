# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-15 10:43 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `e897bad` (feat(dev): declare rgp in suite-development systemPackages)
- **Working Tree:** Clean
- **Live NixOS Generation:** Generation 122 (Activated; 34.5 GiB closure, 2,840 store paths)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `e7f26cc6-0a0d-4875-9c75-0490311e76bd` (current), Antigravity `30dbfe1b-a3e7-4125-bf93-699888b8302a`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Installed `rgp` into `environment.systemPackages` and activated Gen 122.
- [x] Declared `pkgs.rgp` in `suite-development.environment.systemPackages` ([`modules/suites/development/default.nix`](file:///home/nnon/lunar-witches/modules/suites/development/default.nix)); activated Generation 122.
- [x] Added `ms-vscode.cpptools` to VS Code extensions ([`modules/users/nnon/development.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/development.nix)); activated Generation 121.
- [x] Integrated `digital-egro` as `Digital++` (`flake.nix`, `modules/suites/desktop/apps.nix`): replaces ad-hoc `nix run` script with pinned flake input, native CLI wrapper (`digital++`, `digital-egro`), and `Digital++` `.desktop` entry. Activated Generation 121.
- [x] Packaged AMD Radeon Developer Tool Suite (RGP, RMV, RRA, RDP, RGA) in `pkgs/radeon-developer-tool-suite` with RDNA 3.5 APU support; exported to overlays.
- [x] Declared `programs.gh` in Home Manager (`modules/users/nnon/development.nix`); activated Generation 117.

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

33. **Integrated ArtCraft Apps (`nix-craftapps`, `suite-desktop-apps`):**
    - Added `olafkfreund/nix-craftapps` flake input, configured PhotoCraft, FilmCraft, PdfCraft with `linkFonts = true`.
34. **Committed Boulesis Reasoning & Sampling Tuning (`023deae`, `modules/suites/ai/prose.nix`):**
    - Reasoning guards and sampling set configured in `llama-swap`; live since Generation 112.
35. **Declared `skills` CLI (`206c2e3`, `modules/users/nnon/development.nix`):**
    - `pkgs.skills` (vercel-labs/skills 1.7.1) in `home.packages`; activated Generation 115.
36. **Resolved OpenSSH Empty `SSH_ASKPASS` Bug (`plasma.nix`, `shell.nix`):**
    - Enabled `programs.ssh.enableAskPassword = true;` and set `SSH_ASKPASS = "/run/current-system/sw/bin/ksshaskpass"`.
    - Fixed `ssh_askpass: exec(): No such file or directory` failure on encrypted SSH keys; activated Gen 116.
37. **Declared GitHub CLI `programs.gh` (`modules/users/nnon/development.nix`):**
    - Configured `programs.gh` with `git_protocol: "ssh"`, fish completions, and git credential helper integration.
    - Activated Generation 117.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
