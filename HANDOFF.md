# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-16 12:03 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `60ffe5c` (pending commit for znver4 kernel switch)
- **Working Tree:** Clean (activating Generation 131)
- **Live NixOS Generation:** Generation 131 (Activated; Linux 7.2.10-cachyos-lto-znver4, 34.8 GiB closure, 2,847 store paths)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `ff8537d6-877f-425d-b3b8-9df3e661484b` (current), Antigravity `1e53cd57-002a-45f4-b9cf-b5af10c2f946`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Switched to Zen 4 Clang ThinLTO CachyOS kernel (`pkgs.linuxPackages_cachyos-lto-znver4`) and activated Generation 131.
- [x] Switched `boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4` in [`hosts/lunar-qualia/default.nix`](file:///home/nnon/lunar-witches/hosts/lunar-qualia/default.nix).
- [x] Verified binary cache substitution from `nyx-cache.chaotic.cx` with zero compilation.
- [x] Updated [ADR 0002](file:///home/nnon/lunar-witches/retrospects/adr/0002-cachyos-bore-kernel.md).
- [x] Activated Generation 131 on live system.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–30):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

42. **Decoupled Local AI Serving, Isolated AMD Devtools & Dynamic GPU Reset (`61377de`):**
    - Migrated `llama-swap`, `mkServerCmd`, and local models from `suite-ai-prose` to `suite-ai-local`.
    - Added `hardware.amdgpu.development` option and dynamic `amdgpu-reset` system utility.
43. **Automated Pi Extension & Model Updates on Activation (`c4ea763`, `modules/suites/ai/pi-coding-agent.nix`):**
    - Hooked `home.activation.updatePi` DAG hook to run `pi update --models` and `pi update --extensions`.
44. **Added Foliate EPUB Reader & MIME Associations (`72c702c`, `suite-desktop-apps`):**
    - Declared Foliate and registered `application/epub+zip` MIME associations.
45. **Migrated from Compromised `nix-cachyos-kernel` to Chaotic-Nyx (`b840914`):**
    - Replaced `xddxdd/nix-cachyos-kernel` with `chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"`.
    - Purged dead Attic server and trusted `nyx-cache.chaotic.cx` + `@wheel` in `modules/core/default.nix`.
    - Activated Generation 130.
46. **Adopted Zen 4 Clang ThinLTO CachyOS Kernel (`pkgs.linuxPackages_cachyos-lto-znver4`):**
    - Switched `boot.kernelPackages` to `pkgs.linuxPackages_cachyos-lto-znver4` for Strix Halo silicon instruction tuning.
    - Verified instantaneous cache downloads from `nyx-cache.chaotic.cx`; activated Generation 131.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
