# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **OpenCode (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-multi-session-continuity-architecture-antigravity--opencode) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-31 13:09 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `3861386`
- **Working Tree:** Clean (Generation 197 active)
- **Live NixOS Generation:** Generation 197 (Linux 7.2.8-cachyos)
- **Active Agent Stack:** OpenCode v2.1.1 + Pi Coding Agent v1.4.0 + `reasoning/qwen3.8-26b-a4b` on `llama-swap` (`triellama.cpp`, `--no-reasoning-preserve`, `--reasoning-loop-guard force-close`, `repeatPenalty = 1.02`, `dryMultiplier = 0.50`, `dryAllowedLength = 5`, `temp = 0.70`).
- **Unified Prompt Directives:** `~/.agents/models/Qwen3.8-26B-A4B.md` (read dynamically by both Pi and OpenCode).

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi, OpenCode & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `ed26c4a1-4ba0-4835-b4d5-f0598e9979fe` (current).

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Plasma desktop indexing and system stabilization.
- [x] Added `home.activation.kbuildsycoca` to `modules/users/nnon/plasma.nix`.
- [x] Documented symlink inotify behavior in `retrospects/troubleshooting/nixos-desktop-quirks.md`.
- [x] Verified full-graph Nix dry-run evaluation (`nix build --dry-run`).
- [x] Deployed and activated via `nh os switch` (Generation 197 verified).

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–71):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 3 Milestones)

72. **Claude Desktop, Open WebUI Suite & Gemma 4 26B Heretic Integration (`348c070`):**
    - Added `suite-ai-claude` (`modules/suites/ai/claude.nix`) wrapping `claude-desktop-fhs` and `claude-code`.
    - Added `suite-ai-open-webui` (`modules/suites/ai/open-webui.nix`) with custom Python overlay pinning `mcp = 1.30.0`.
    - Upgraded `local.nix` with configurable `batchSize`/`ubatchSize` and swapped in `unleashed/gemma-4-26B-A4B-it` (Uncensored Heretic Q4_K_S).
    - Registered `open-webui.service` in Service Deck desktop configuration.
73. **KScreen/Baloo Crash Fixes, GPU Boost Query Decoupling & r2modman (`bd107f7`, `969290b`):**
    - Decoupled `amdgpu-boost` metrics queries (`json`/`status`) from display rate switching, stopping 1000ms `kscreen-doctor` storms.
    - Bound `amdgpu-boost.service` to `graphical-session.target` and guarded all `kscreen-doctor` calls with active display checks.
    - Declaratively provisioned `QT_QPA_PLATFORM=offscreen` as drop-in for `kde-baloo.service` in `suite-desktop-plasma`.
    - Integrated `r2modman` into `suite-gaming` and registered `x-scheme-handler/ror2mm` in `xdg.mimeApps` for Thunderstore web installs.
74. **Google Antigravity IDE Integration (`7ea4865`):**
    - Provisioned `google-antigravity-ide` in `suite-ai-antigravity` (`modules/suites/ai/antigravity.nix`).
    - Registered `x-scheme-handler/antigravity = "antigravity-ide.desktop"` in `modules/users/nnon/desktop.nix`.
    - Verified generation 196 activation and default MIME association.
75. **Declarative Plasma KSycoca Refresh Hook:**
    - Added `home.activation.kbuildsycoca` in `modules/users/nnon/plasma.nix` ensuring every `nh os switch` immediately rebuilds the KSycoca application index without restarting plasmashell.
    - Documented NixOS symlink inotify limitation in `retrospects/troubleshooting/nixos-desktop-quirks.md#14`.
