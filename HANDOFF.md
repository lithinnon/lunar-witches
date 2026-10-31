# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **OpenCode (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-multi-session-continuity-architecture-antigravity--opencode) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-31 12:20 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `969290b`
- **Working Tree:** Clean (`master`)
- **Live NixOS Generation:** Generation 169 (Linux 7.2.8-cachyos)
- **Active Agent Stack:** OpenCode v2.1.1 + Pi Coding Agent v1.4.0 + `reasoning/qwen3.8-26b-a4b` on `llama-swap` (`triellama.cpp`, `--no-reasoning-preserve`, `--reasoning-loop-guard force-close`, `repeatPenalty = 1.02`, `dryMultiplier = 0.50`, `dryAllowedLength = 5`, `temp = 0.70`).
- **Unified Prompt Directives:** `~/.agents/models/Qwen3.8-26B-A4B.md` (read dynamically by both Pi and OpenCode).

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi, OpenCode & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `ed26c4a1-4ba0-4835-b4d5-f0598e9979fe` (current).

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Fix KScreen/Baloo crash loops, decouple `amdgpu-boost` queries from display mutations, and add `r2modman` to the gaming suite.
- [x] Integrated `r2modman` into `suite-gaming` and registered `x-scheme-handler/ror2mm` in `xdg.mimeApps.defaultApplications` for 1-click Thunderstore web installs.
- [x] Fixed `amdgpu-boost` 1000ms widget query storm: decoupled state queries from display mode switching.
- [x] Bound `amdgpu-boost.service` to `graphical-session.target` and guarded `kscreen-doctor` calls with display session checks.
- [x] Declaratively provisioned `QT_QPA_PLATFORM=offscreen` on `kde-baloo.service` in `suite-desktop-plasma`.
- [x] Verified full-graph Nix dry-run evaluation (`nix build --dry-run`).
- [ ] Apply live system generation switch (`nh os switch`).
- [ ] Verify `r2modman` and clean `kscreen-doctor` logs on running desktop.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–70):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 3 Milestones)

71. **Master Directives, Syntax-Safe Sampling & Unified Prompt Alignment (`cd739f2`, `c1f7215`, `c71231b`):**
    - Set `tool_call_format = 'json'` in `chat_template.jinja` (`9fbd8e7`), fixing corrupted XML parameter parsing in `llama-server`.
    - Tuned `dryAllowedLength = 5`, `drySequenceBreaker = "none"`, and `repeatPenalty = 1.02` in `local.nix`.
    - Consolidated agent instructions into `~/.agents/models/Qwen3.8-26B-A4B.md` and deleted `modules/suites/ai/opencode/instructions.md`.
72. **Claude Desktop, Open WebUI Suite & Gemma 4 26B Heretic Integration (`348c070`):**
    - Added `suite-ai-claude` (`modules/suites/ai/claude.nix`) wrapping `claude-desktop-fhs` and `claude-code`.
    - Added `suite-ai-open-webui` (`modules/suites/ai/open-webui.nix`) with custom Python overlay pinning `mcp = 1.30.0`.
    - Upgraded `local.nix` with configurable `batchSize`/`ubatchSize` and swapped in `unleashed/gemma-4-26B-A4B-it` (Uncensored Heretic Q4_K_S).
    - Registered `open-webui.service` in Service Deck desktop configuration.
73. **KScreen/Baloo Crash Fixes, GPU Boost Query Decoupling & r2modman:**
    - Decoupled `amdgpu-boost` metrics queries (`json`/`status`) from display rate switching, stopping 1000ms `kscreen-doctor` storms.
    - Bound `amdgpu-boost.service` to `graphical-session.target` and guarded all `kscreen-doctor` calls with active display checks.
    - Declaratively provisioned `QT_QPA_PLATFORM=offscreen` for `kde-baloo.service` in `suite-desktop-plasma`.
    - Integrated `r2modman` into `suite-gaming` and registered `x-scheme-handler/ror2mm` in `xdg.mimeApps` for Thunderstore web installs.
