# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-16 18:37 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `b256b4a`
- **Working Tree:** Clean (activated Generation 135)
- **Live NixOS Generation:** Generation 135 (Activated; Linux 7.2.10-cachyos-lto-znver4, 34.8 GiB closure, 2,848 store paths)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `f8ca63e7-586c-411f-beed-207ca745e382` (current), Antigravity `e48b2d84-6643-419f-9db1-c9915189afd7`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Purged obsolete `--cache-reuse` flag from `llama-swap` runner following `beellama.cpp` argument parser refactor.
- [x] Identified `--cache-reuse` removed in `beellama.cpp` commit `7db0738a` (fails CLI parsing).
- [x] Removed `--cache-reuse 256` from `mkServerCmd` in `modules/suites/ai/local.nix`.
- [x] Formatted and dry-built configuration; verified rendered `~/.config/llama-swap.yml`.
- [x] Activated Generation 135 via `nh os switch` and restarted `llama-swap.service`.

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

43. **Automated Pi Extension & Model Updates on Activation (`c4ea763`, `modules/suites/ai/pi-coding-agent.nix`):**
    - Hooked `home.activation.updatePi` DAG hook to run `pi update --models` and `pi update --extensions`.
44. **Added Foliate EPUB Reader & MIME Associations (`72c702c`, `suite-desktop-apps`):**
    - Declared Foliate and registered `application/epub+zip` MIME associations.
45. **Migrated from Compromised `nix-cachyos-kernel` to Chaotic-Nyx (`b840914`):**
    - Replaced `xddxdd/nix-cachyos-kernel` with `chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"`.
    - Purged dead Attic server and trusted `nyx-cache.chaotic.cx` + `@wheel` in `modules/core/default.nix`.
    - Activated Generation 130.
46. **Adopted Zen 4 Clang ThinLTO CachyOS Kernel (`pkgs.linuxPackages_cachyos-lto-znver4`, `b236829`):**
    - Switched `boot.kernelPackages` to `pkgs.linuxPackages_cachyos-lto-znver4` for Strix Halo silicon instruction tuning.
    - Verified instantaneous cache downloads from `nyx-cache.chaotic.cx`; activated Generation 131.
47. **Resolved Flatpak CJK Font Rendering & Dangling Symlinks (`9a74358`, `bd99dc0`):**
    - Declaratively provisioned `/var/lib/flatpak/overrides/global` via `systemd.tmpfiles.rules` (`modules/suites/desktop/apps.nix`) granting `/nix/store:ro` to resolve `/run/host/fonts` symlinks.
    - Defined explicit CJK fallback prioritization (`fonts.fontconfig.defaultFonts`) in `modules/suites/desktop/fonts.nix`.
    - Activated Generation 132.
48. **Purged Obsolete `--cache-reuse` Flag from `llama-swap` Runner (`2b02c5f`, `modules/suites/ai/local.nix`):**
    - Removed obsolete `--cache-reuse 256` flag following `beellama.cpp` argument parser refactor (`7db0738a`).
    - Verified all flags against live recompiled `llama-server` binary; activated Generation 135 and restarted `llama-swap.service`.
49. **Added `pkgs.openssl` to AI DevShells (`b256b4a`, `shells/loom.nix`, `shells/rocm.nix`):**
    - Added OpenSSL headers/libraries to both package sets and runtime `LD_LIBRARY_PATH` in `torch-dev` and `loom-dev`.


---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
