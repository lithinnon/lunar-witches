# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (Qwen 3.8 26B-A4B)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--qwen-38-26b-a4b) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-26 00:04 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `a587d4c`
- **Working Tree:** Dirty (`modules/suites/ai/pi-coding-agent.nix`, `retrospects/history/2026-10-session-ledger.md`)
- **Live NixOS Generation:** Generation 164 (Linux 7.3.0-cachyos)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `f22d1737-c8e0-48d5-b804-080941a37627` (current), Antigravity `bc2bb3d8-6692-4246-9429-a36d41336f17`, Pi `2026-10-25T16-36-02-307Z_01a173eb-4a83-773d-b7c5-097168627332`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Configured `defaultThinkingLevel = "high"`, system invariants, and agent guard extension (loop breaker + output truncator) for Pi Coding Agent (`modules/suites/ai/pi-coding-agent.nix`), with upstream `froggeric/Qwen-Fixed-Chat-Templates` (v22.5) mapping `high` to `xhigh`.
- [x] Formatted and checked syntax via `nix fmt`.
- [x] Evaluated dry-run build via `nix build --dry-run`.
- [ ] Build candidate generation via `nh os build`.
- [ ] Activate generation via `nh os switch`.
- [ ] Validate live Pi configuration and thinking level startup.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35, 48, 51–61):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 4 Milestones)

61. **Configured `reasoning/qwen3.8-26b-a4b` & Purged LFM 24B in `llama-swap` (`modules/suites/ai/local.nix`):**
    - Parameterized `mkServerCmd` for local weights (`model`), multimodal projectors (`mmproj`), Jinja chat templates (`chatTemplate`), and safe radix cache limits.
    - Declared `reasoning/qwen3.8-26b-a4b` with 128k context, symmetric `snc4` KV cache, 512 `bf16` tail tokens, and `--spec-type draft-mtp`.
    - Removed `agentic/lfm2.5-24b-a2b` from models and `groups.chat.members`; switched to Generation 161.
62. **Switch Qwen KV Cache to Asymmetric SNC8 Value (`a512b6a`, `modules/suites/ai/local.nix`):**
    - Switched `cache_type_v` to `snc8` while keeping `cache_type_k` as `snc4` for higher numerical stability and fidelity.
    - Switched and activated Generation 164.
63. **Updated Qwen3.8-26B-A4B Model & Template Paths (`a587d4c`, `modules/suites/ai/local.nix`):**
    - Updated model path from `qwen-3.8-26b-moe` to `qwen3.8-26b-a4b` directory.
    - Updated chatTemplate path similarly for Jinja templates.
    - Committed with `feat(ai): update qwen3.8-26b-a4b model and template paths`.
64. **Configured Pi Thinking Level (`high`), System Invariants & Agent Guard (`modules/suites/ai/pi-coding-agent.nix`):**
    - Set `defaultThinkingLevel = "high"`, which maps directly to `xhigh` in upstream froggeric v22.5 chat template.
    - Added `appendSystem` cognitive invariants (domain boundaries, targeted CLI probing, anti-looping).
    - Provisioned `loop-breaker.ts` extension with tool-call cycle detection, output truncation (>100 lines/6KB), and empty-search annotation.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
