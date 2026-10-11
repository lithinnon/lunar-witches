# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity
- **Timestamp:** 2026-10-11 11:12 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `1f2bf30`
- **Working Tree:** Clean
- **Live NixOS Generation:** Generation 109 (Activated; 31.6 GiB closure, 2,808 store paths)

### Active & Prior Session Traces (Raw Forensics)
- **Antigravity Session ID:** `d0afd4c3-9ac9-42c7-8b57-ff726f2c6577`  
  *Path:* `~/.gemini/antigravity-cli/brain/d0afd4c3-9ac9-42c7-8b57-ff726f2c6577/.system_generated/logs/transcript.jsonl`
- **Pi Session ID:** `01a10a7f-7d9a-753c-9b68-372aa214bb10`  
  *Path:* `~/.config/pi/agent/sessions/--home-nnon-lunar-witches--/2026-10-05T05-18-09-818Z_01a10a7f-7d9a-753c-9b68-372aa214bb10.jsonl`

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Multi-session continuity architecture and routine flake maintenance.
- [x] Switched `beellama.cpp` inference engine to standard ROCm HIP.
- [x] Enabled Digital wire tooltips declaratively in `~/.digital.cfg` (Generation 108).
- [x] Routine flake inputs update & switch to Generation 109.
- [x] Archived completed historical ledger items 1–31 to `retrospects/history/2026-10-session-ledger.md`.
- [ ] Formalize Session Rotation & Continuity Protocol in `AGENTS.md`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–31):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

28. **Packaged `beellama.cpp` and Purged Nixpkgs `llama-cpp-vulkan` (`pkgs/beellama`):**
    - Created in-tree derivation wrapping local build, cutting 87.3 MiB.
29. **Created Dedicated `suite-ai-local` & Configured 64k `snc8` Disk Cache:**
    - Decoupled `beellama` into `modules/suites/ai/local.nix`.
    - Configured Boulesis 26B A4B in `llama-swap`: 64k context, `snc8`/`snc8` KV cache, 1024 `bf16` tail tokens, 0-RAM with 16 GiB NVMe radix disk tier.
30. **Switched `beellama.cpp` to Native Standard ROCm HIP (`pkgs/beellama`, `modules/suites/ai/local.nix`):**
    - Built with `build.sh` into `build/` linked to TheRock 10.1 HIP (`libamdhip64.so.7`) and `hipBLAS`.
    - Added `backend ? "rocm"` parameter to package and `suites.ai.local.backend`.
31. **Enabled Wire Tooltips in Digital (`modules/users/nnon/desktop.nix`):**
    - Declared `<entry><string>wireToolTips</string><boolean>true</boolean></entry>` in `home.file.".digital.cfg"`.
    - Overcame read-only nix store symlink limitation in Home Manager.
32. **Routine Flake Inputs Update (`flake.lock`):**
    - Bumped `nixpkgs` (2026-10-08 -> 2026-10-10), `home-manager`, `antigravity-nix`, `bedrock-on-linux`.
    - Activated Generation 109 (+10.6 MiB net diff; KDE Gear 26.08.2, Brave 1.97, Obsidian 1.14, Telegram 7.2.9).

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
