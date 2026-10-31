# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **OpenCode (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-multi-session-continuity-architecture-antigravity--opencode) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-31 11:48 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `348c070`
- **Working Tree:** Clean (`master`)
- **Live NixOS Generation:** Generation 169 (Linux 7.2.8-cachyos)
- **Active Agent Stack:** OpenCode v2.1.1 + Pi Coding Agent v1.4.0 + `reasoning/qwen3.8-26b-a4b` on `llama-swap` (`triellama.cpp`, `--no-reasoning-preserve`, `--reasoning-loop-guard force-close`, `repeatPenalty = 1.02`, `dryMultiplier = 0.50`, `dryAllowedLength = 5`, `temp = 0.70`).
- **Unified Prompt Directives:** `~/.agents/models/Qwen3.8-26B-A4B.md` (read dynamically by both Pi and OpenCode).

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi, OpenCode & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `ed26c4a1-4ba0-4835-b4d5-f0598e9979fe` (current).

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Integration of Claude suite, Open WebUI with patched Python 3.14 MCP overlay, and Gemma 4 26B A4B Heretic llama-swap model.
- [x] Provisioned `suite-ai-claude` (`claude-desktop-fhs` via flake input `claude-desktop` + `claude-code`).
- [x] Provisioned `suite-ai-open-webui` with Python 3.14 overlay pinning `mcp = 1.30.0` (bypassing `streamable_http` crash) and wired Service Deck entry.
- [x] Parameterized `batchSize`/`ubatchSize` in `local.nix` and replaced `gemma-4-12B-it` with `unleashed/gemma-4-26B-A4B-it` in `agents` group.
- [x] Verified full-graph Nix dry-run evaluation (`nix build --dry-run`).
- [ ] Deploy and activate via `nh os switch`.
- [ ] Verify `open-webui.service` and Gemma 4 26B A4B model under `llama-swap`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–66):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 3 Milestones)

70. **Anti-Looping Architecture: DRY Sampling, Loop Guard & Intermediate Reasoning Stripping (`cb6d703`):**
    - Diagnosed empirical root cause of multi-turn looping in `qwen3.8-26b-a4b`: intermediate `<think>` blocks kept in KV cache acted as autoregressive attractor traps.
    - Generalized `mkServerCmd` in `local.nix` with typed options and universal defaults (`reasoningBudget = 4096`, `reasoningLoopGuard = "force-close"`).
71. **Master Directives, Syntax-Safe Sampling & Unified Prompt Alignment (`cd739f2`, `c1f7215`, `c71231b`):**
    - Set `tool_call_format = 'json'` in `chat_template.jinja` (`9fbd8e7`), fixing corrupted XML parameter parsing in `llama-server`.
    - Tuned `dryAllowedLength = 5`, `drySequenceBreaker = "none"`, and `repeatPenalty = 1.02` in `local.nix`.
    - Consolidated agent instructions into `~/.agents/models/Qwen3.8-26B-A4B.md` and deleted `modules/suites/ai/opencode/instructions.md`.
72. **Claude Desktop, Open WebUI Suite & Gemma 4 26B Heretic Integration:**
    - Added `suite-ai-claude` (`modules/suites/ai/claude.nix`) wrapping `claude-desktop-fhs` and `claude-code`.
    - Added `suite-ai-open-webui` (`modules/suites/ai/open-webui.nix`) with custom Python overlay pinning `mcp = 1.30.0` to resolve `streamable_http` crash.
    - Upgraded `local.nix` with configurable `batchSize`/`ubatchSize` and swapped in `unleashed/gemma-4-26B-A4B-it` (Uncensored Heretic Q4_K_S, `snc4` KV cache, 1024 tail tokens).
    - Registered `open-webui.service` in Service Deck desktop configuration.
