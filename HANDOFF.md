# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--qwen-38-26b-a4b) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-25 20:54 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `02287b2`
- **Working Tree:** Clean (Switched and active)
- **Live NixOS Generation:** Generation 164 (Linux 7.3.0-cachyos)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `bc2bb3d8-6692-4246-9429-a36d41336f17` (current), Antigravity `c18639b1-a221-4c2b-9fb7-eedb5d22d0d3`, Antigravity `fad59a5a-831e-45a2-9d4d-0a784bde3aba`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Configured asymmetric SNC KV cache quantization for `reasoning/qwen3.8-26b-a4b` (`snc4` key + `snc8` value); activated Generation 164.
- [x] Formatted and checked syntax via `nix fmt`.
- [x] Evaluated dry-run build via `nix build --dry-run`.
- [x] Built candidate generation via `nh os build`.
- [x] Switched and activated Generation 164 via `nh os switch`.
- [x] Restarted `llama-swap.service` and validated live execution via `pi -p`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35, 48, 51–58):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 4 Milestones)

59. **Conformed Shell & Toolchains to XDG Base Directory Specification (`modules/core/default.nix`, `modules/users/nnon/default.nix`, `modules/users/nnon/shell.nix`):**
    - Configured system-level `nix.settings.use-xdg-base-directories = true;` to place Nix channels and defexpr under `$XDG_STATE_HOME`.
    - Configured user-level `xdg.enable = true;`, standard XDG session variables (`CARGO_HOME`, `DOTNET_CLI_HOME`, `CODEX_HOME`, `TRITON_HOME`, `PYTHON_HISTORY`, `GTK2_RC_FILES`, `NPM_CONFIG_*`, `_JAVA_OPTIONS`), `sessionPath`, and `wget` alias.
    - Migrated existing home dotfiles into their corresponding XDG destinations (including Digital circuit preferences to `~/.config/java/.userPrefs`).
    - Provisioned declarative `xdg.configFile."xdg-ninja/ignore"` suppressing brittle/high-risk items (`.gnupg`, `.pulse-cookie`, `.zoom`) while keeping upstream-hardcoded Category C candidates visible.
60. **Integrated Typst Toolchain & VS Code Extension (`f9d6876`, `modules/suites/development/default.nix`, `modules/users/nnon/development.nix`):**
    - Added `typst` (0.15.1), `tinymist` (0.15.10 LSP), and `typstyle` (0.15.2 code formatter) to `suite-development`.
    - Added `vscode-extensions.myriad-dreamin.tinymist` to user VS Code profile.
    - Switched and activated Generation 158; verified PDF compilation.
61. **Configured `reasoning/qwen3.8-26b-a4b` & Purged LFM 24B in `llama-swap` (`modules/suites/ai/local.nix`):**
    - Parameterized `mkServerCmd` for local weights (`model`), multimodal projectors (`mmproj`), Jinja chat templates (`chatTemplate`), and safe radix cache limits.
    - Declared `reasoning/qwen3.8-26b-a4b` with 128k context, symmetric `snc4` KV cache, 512 `bf16` tail tokens, and `--spec-type draft-mtp`.
    - Removed `agentic/lfm2.5-24b-a2b` from models and `groups.chat.members`; switched to Generation 161.
62. **Migrated Pi Coding Agent to Local Qwen & Purged MiMo (`modules/suites/ai/pi-coding-agent.nix`, `AGENTS.md`):**
    - Configured `programs.pi-coding-agent.models` pointing to `llama-swap` (`http://127.0.0.1:8080/v1`).
    - Set `defaultProvider = "llama-swap"` and `defaultModel = "reasoning/qwen3.8-26b-a4b"`.
    - Removed `pi-xiaomi-mimo-provider` extension and purged Xiaomi credentials from `auth.json`.
    - Switched and activated Generation 162; verified default headless Pi invocation with zero flags.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
