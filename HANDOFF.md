# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **OpenCode (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-multi-session-continuity-architecture-antigravity--opencode) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-28 20:25 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `c1f7215`
- **Working Tree:** Clean (`master`)
- **Live NixOS Generation:** Generation 169 (Linux 7.2.8-cachyos)
- **Active Agent Stack:** OpenCode v2.1.1 + Pi Coding Agent v1.4.0 + `reasoning/qwen3.8-26b-a4b` on `llama-swap` (`triellama.cpp`, `--no-reasoning-preserve`, `--reasoning-loop-guard force-close`, `repeatPenalty = 1.02`, `dryMultiplier = 0.50`, `dryAllowedLength = 5`, `temp = 0.70`).
- **Unified Prompt Directives:** `~/.agents/models/Qwen3.8-26B-A4B.md` (read dynamically by both Pi and OpenCode).

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi, OpenCode & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `f22d1737-c8e0-48d5-b804-080941a37627` (current).

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Unified prompt architecture at `~/.agents/models/Qwen3.8-26B-A4B.md`, syntax-safe DRY sampling (`dryAllowedLength = 5`), JSON tool calling default in `chat_template.jinja`, and purge of redundant in-tree prompt files and legacy plugins.
- [x] Fixed `chat_template.jinja` line 2 default `tool_call_format` to `'json'`, enabling clean OpenAI function calling on `llama-server`.
- [x] Relaxed `dryAllowedLength` from 2 $\to$ 5 and `repeatPenalty` to 1.02 in `local.nix`, preventing false penalties on JSON syntax quotes/braces.
- [x] Authored and relocated master operational directives to `~/.agents/models/Qwen3.8-26B-A4B.md` with temporal (2026) and web search authority guardrails.
- [x] Wired OpenCode `instructions = [ "${config.home.homeDirectory}/.agents/models/Qwen3.8-26B-A4B.md" ]` and symlinked Pi `APPEND_SYSTEM.md`.
- [x] Deleted redundant in-tree `modules/suites/ai/opencode/instructions.md` and purged legacy plugins.
- [x] Evaluated flake dry-run build (`nix build --dry-run` passed 100%).

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
71. **Master Directives, Syntax-Safe Sampling & Unified Prompt Alignment (`cd739f2`, `c1f7215`):**
    - Set `tool_call_format = 'json'` in `chat_template.jinja` (`9fbd8e7`), fixing corrupted XML parameter parsing in `llama-server`.
    - Tuned `dryAllowedLength = 5` and `repeatPenalty = 1.02` in `local.nix`, preventing DRY penalty on syntax delimiters (`"}`, `",`).
    - Consolidated agent instructions into `~/.agents/models/Qwen3.8-26B-A4B.md` (read dynamically by Pi and OpenCode) and deleted `modules/suites/ai/opencode/instructions.md`.
