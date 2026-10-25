# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **OpenCode (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-multi-session-continuity-architecture-antigravity--opencode) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-26 01:12 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `ffeab08`
- **Working Tree:** Clean (`master`)
- **Live NixOS Generation:** Generation 164 (Linux 7.3.0-cachyos)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi, OpenCode & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `4ae41731-d0f6-4907-b645-9cb43e4f5fb9` (current), Pi legacy `2026-10-25T17-24-48-368Z_01a17417-f06f-70cc-8719-df5a7ac0c7fc`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Migrated from Pi Coding Agent to OpenCode suite (`modules/suites/ai/opencode.nix`), configured `opencode.json` with local `llama-swap`, native MCP `nixos`, websearch/fetch permissions, and AGENTS.md ambient instructions.
- [x] Implemented `modules/suites/ai/opencode.nix` and deleted `modules/suites/ai/pi-coding-agent.nix`.
- [x] Swapped module import in `hosts/lunar-qualia/default.nix` and `modules/suites/default.nix`.
- [x] Updated shell aliases in `modules/users/nnon/shell.nix`.
- [x] Updated multi-agent continuity specification in `AGENTS.md`.
- [ ] Format and check syntax via `nix fmt ./**.nix`.
- [ ] Evaluate dry-run build via `nix build --dry-run`.
- [ ] Build candidate generation via `nh os build`.
- [ ] Activate generation via `nh os switch`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35, 48, 51–64):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 4 Milestones)

62. **Switch Qwen KV Cache to Asymmetric SNC8 Value (`a512b6a`, `modules/suites/ai/local.nix`):**
    - Switched `cache_type_v` to `snc8` while keeping `cache_type_k` as `snc4` for higher numerical stability and fidelity.
    - Switched and activated Generation 164.
63. **Updated Qwen3.8-26B-A4B Model & Template Paths (`a587d4c`, `modules/suites/ai/local.nix`):**
    - Updated model path from `qwen-3.8-26b-moe` to `qwen3.8-26b-a4b` directory.
    - Updated chatTemplate path similarly for Jinja templates.
    - Committed with `feat(ai): update qwen3.8-26b-a4b model and template paths`.
64. **Configured Pi Thinking Level (`high`), System Invariants & Agent Guard (`modules/suites/ai/pi-coding-agent.nix`):**
    - Set `defaultThinkingLevel = "high"`, which maps directly to `xhigh` in upstream froggeric v22.5 chat template.
    - Added `appendSystem` cognitive invariants and `loop-breaker.ts` extension.
65. **Fully Migrated from Pi to OpenCode Suite (`suite-ai-opencode`):**
    - Created `modules/suites/ai/opencode.nix` with declarative `opencode.json` (pointing to `llama-swap` provider, `reasoning/qwen3.8-26b-a4b`, native MCP `nixos`, websearch/fetch, and `AGENTS.md` instructions).
    - Removed `modules/suites/ai/pi-coding-agent.nix` and switched host leaf `lunar-qualia` composition.
    - Updated shell aliases in `modules/users/nnon/shell.nix` (`nix-agent-opencode` / `nix-agent`).
    - Updated multi-agent continuity specification in `AGENTS.md`.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
