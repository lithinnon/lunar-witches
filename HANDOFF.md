# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-25 11:46 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `d104e2b`
- **Working Tree:** Clean (Switched and active)
- **Live NixOS Generation:** Generation 156 (Linux 7.2.11-cachyos-lto-znver4)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `fad59a5a-831e-45a2-9d4d-0a784bde3aba` (current), Antigravity `9e11d61f-32ec-444c-a6a2-0f1837069929`, Antigravity `6a279548-478f-4fe9-a6a7-7b4d58ca9df7`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Conformed system and user environments to XDG Base Directory specs and migrated legacy dotfiles.
- [x] Declared system-level `nix.settings.use-xdg-base-directories = true;` in `modules/core/default.nix`.
- [x] Declared user-level `xdg.enable = true;` in `modules/users/nnon/default.nix`.
- [x] Declared XDG environment variables (`CARGO_HOME`, `DOTNET_CLI_HOME`, `CODEX_HOME`, `TRITON_HOME`, `PYTHON_HISTORY`, `GTK2_RC_FILES`, `NPM_CONFIG_*`), session path, and `wget` HSTS alias in `modules/users/nnon/shell.nix`.
- [x] Safely migrated 9 existing home dotfiles into their corresponding XDG destinations.
- [x] Validated with `xdg-ninja` that all Category A legacy dotfiles are cleared.
- [x] Evaluated top-level system dry-run successfully (`nix build .#nixosConfigurations.lunar-qualia.config.system.build.toplevel --dry-run`).
- [x] Activated Generation 156 via `nh os switch /home/nnon/lunar-witches`.
- [ ] Investigate/configure `systemd.services.NetworkManager.restartIfChanged = false;` to prevent network drop during live switches.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35, 48, 51–55):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 4 Milestones)

56. **Allocated 1024 MiB RAM Cache Specifically to Boulesis (`modules/suites/ai/local.nix`):**
    - Parameterized `cacheRam ? null` in `mkServerCmd`; added `-cram 1024` to Boulesis in `extraFlags`.
    - Switched and activated Generation 150; validated `llama-swap.service`.
57. **Integrated Hugging Face `git-xet`, Git LFS & Pinned RDTS Patchelf (`fe878ff`, `modules/users/nnon/development.nix`, `pkgs/radeon-developer-tool-suite/default.nix`):**
    - Declared `programs.git.lfs.enable = true` and `lfs."customtransfer.xet"` agent in Home Manager.
    - Added `pkgs.git-xet` to `home.packages`.
    - Fixed RDTS build failure under nixpkgs `patchelf 0.19.2` by pinning `patchelf 0.15.2` in `nativeBuildInputs`.
    - Switched and activated Generation 153.
58. **Purged Goverlay, Added `npm:pi-subagents`, Updated Flake Inputs & Fixed `mcp-nixos` (`312d52b`, `modules/suites/ai/pi-coding-agent.nix`, `pkgs/default.nix`, `flake.lock`):**
    - Removed `goverlay` and purged runtime directories (`~/.config/{goverlay,Goverlay,MangoHud,vkBasalt,vkSumi}`, `afmf-linux` implicit layer and libs).
    - Added `"npm:pi-subagents"` package to Pi coding agent suite.
    - Updated all flake inputs via `nix flake update`.
    - Overrode `fastmcp-slim` with `mcp = pyFinal.mcp_1` (1.29.0) in `pkgs/default.nix` to fix `mcp-nixos` evaluation with upstream nixpkgs 26.11 bumping `mcp` to 2.x.
59. **Conformed Shell & Toolchains to XDG Base Directory Specification (`modules/core/default.nix`, `modules/users/nnon/default.nix`, `modules/users/nnon/shell.nix`):**
    - Configured system-level `nix.settings.use-xdg-base-directories = true;` to place Nix channels and defexpr under `$XDG_STATE_HOME`.
    - Configured user-level `xdg.enable = true;`, standard XDG session variables (`CARGO_HOME`, `DOTNET_CLI_HOME`, `CODEX_HOME`, `TRITON_HOME`, `PYTHON_HISTORY`, `GTK2_RC_FILES`, `NPM_CONFIG_*`, `_JAVA_OPTIONS`), `sessionPath`, and `wget` alias.
    - Migrated existing home dotfiles into their corresponding XDG destinations (including Digital circuit preferences to `~/.config/java/.userPrefs`).
    - Provisioned declarative `xdg.configFile."xdg-ninja/ignore"` suppressing brittle/high-risk items (`.gnupg`, `.pulse-cookie`, `.zoom`) while keeping upstream-hardcoded Category C candidates visible.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
