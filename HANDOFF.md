# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-15 11:10 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `7f8a92e` (feat(ai): declare agentic/lfm2.5-24b-a2b in llama-swap with snc4 KV cache)
- **Working Tree:** Clean
- **Live NixOS Generation:** Generation 124 (Activated; 34.5 GiB closure, 2,840 store paths)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `fcf40119-8d7e-4929-8d8b-37114c983a90` (current), Antigravity `e7f26cc6-0a0d-4875-9c75-0490311e76bd`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Declared and activated `agentic/lfm2.5-24b-a2b` in `llama-swap` (Gen 124).
- [x] Declared `agentic/lfm2.5-24b-a2b` with `snc4/snc4` KV cache, 131k context, and Jinja reasoning in [`modules/suites/ai/prose.nix`](file:///home/nnon/lunar-witches/modules/suites/ai/prose.nix); activated Generation 124.
- [x] Declared `RADV_THREAD_TRACE_BUFFER_SIZE = "134217728"` (128 MiB) in [`modules/suites/development/default.nix`](file:///home/nnon/lunar-witches/modules/suites/development/default.nix); activated Generation 123.
- [x] Updated `mesa-vk-trace` to momentary auto-cleanup alias in [`modules/users/nnon/shell.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/shell.nix); activated Generation 123.
- [x] Added `ms-vscode.cpptools` to VS Code extensions ([`modules/users/nnon/development.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/development.nix)); activated Generation 121.
- [x] Integrated `digital-egro` as `Digital++` (`flake.nix`, `modules/suites/desktop/apps.nix`): replaces ad-hoc `nix run` script with pinned flake input, native CLI wrapper (`digital++`, `digital-egro`), and `Digital++` `.desktop` entry. Activated Generation 121.

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
38. **Declared `agentic/lfm2.5-24b-a2b` in `llama-swap` (`7f8a92e`, `modules/suites/ai/prose.nix`):**
    - Configured Liquid AI LFM2.5-24B-A2B QAD-Q4_0 checkpoint with 131k context (`--ctx-size 131072`), `snc4/snc4` KV cache quantization, 1024 `bf16` tail tokens, 16 GiB persistent NVMe radix tier, Flash Attention, Jinja chat templating (`--jinja`), and DeepSeek-format reasoning extraction.
    - Activated Generation 124; verified via `curl http://127.0.0.1:8080/v1/models`.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
