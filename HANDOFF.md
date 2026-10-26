# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **OpenCode (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-multi-session-continuity-architecture-antigravity--opencode) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-26 10:30 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `9e2a094`
- **Working Tree:** Clean (`master`)
- **Live NixOS Generation:** Generation 162 (Linux 7.3.0-cachyos)
- **Active Agent Stack:** OpenCode v2.1.1 (Modularized plugins `fuzzy-edit.js` + `session-title.js`, background `title` agent disabled to prevent slot contention/cache evictions, in-band `set_session_title` native tool with 100% KV cache preservation, 32k output limit, CodeMode disabled).

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi, OpenCode & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `4ae41731-d0f6-4907-b645-9cb43e4f5fb9` (current), Pi legacy `2026-10-25T17-24-48-368Z_01a17417-f06f-70cc-8719-df5a7ac0c7fc`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Completed full migration from Pi to OpenCode (`suite-ai-opencode`) and equipped OpenCode with Aider-style fuzzy edit replacer, Levenshtein typo tolerance, anti-sed guard, and negative-proof annotator.
- [x] Swapped Pi suite for OpenCode suite (`modules/suites/ai/opencode.nix`, `hosts/lunar-qualia/default.nix`).
- [x] Declared SOPS `brave_api_key` integration for native Brave MCP search.
- [x] Implemented OpenCode plugin `${config.xdg.configHome}/opencode/plugins/fuzzy-edit/index.js` with:
  - Pass 1: Line-trimmed relative indentation matching.
  - Pass 2: Levenshtein distance typo tolerance (15% length threshold, repairing perceptual slips like `sites` vs `suites`).
  - Anti-`sed` guard blocking `sed -i` line-arithmetic corruption.
  - Negative-proof annotator (0 matches found banner) and silent failure exit banner.
- [x] Documented Full-Graph Dependency Convergence Invariant and Cognitive Guardrails in `AGENTS.md`.
- [x] Evaluated and built candidate system generation locally via `nh os build`.
- [x] Activated configuration on live host (**Generation 169** active).

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

65. **Fully Migrated from Pi to OpenCode Suite (`suite-ai-opencode`):**
    - Created `modules/suites/ai/opencode.nix` with declarative `opencode.json` (pointing to `llama-swap`, `reasoning/qwen3.8-26b-a4b`, native MCP `nixos`, SOPS `brave_api_key` for Brave search, `snapshots = true`, `formatter = true`).
66. **OpenCode Modularization & Cognitive Invariants (`8c3b904`):**
    - Split inline JS strings into `modules/suites/ai/opencode/plugins/fuzzy-edit.js` and universal cognitive invariants in `instructions.md`.
67. **In-Band Native Titler & Background Title Agent Disabling (`9e2a094`):**
    - Created dedicated plugin `modules/suites/ai/opencode/plugins/session-title.js` registering native `set_session_title` tool (`codemode: false`).
    - Disabled upstream concurrent title agent (`agent.title.disable = true`) eliminating llama-server slot contention and KV cache evictions.
    - Added Cognitive Invariant Rule 9 in `instructions.md` directing 3–8 word session titling on Turn 1 with ~99.9% KV cache preservation.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
