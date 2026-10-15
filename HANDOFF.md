# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-15 20:00 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `72c702c` (feat(desktop): add foliate epub reader and configure mime associations)
- **Working Tree:** Clean
- **Live NixOS Generation:** Generation 129 (Activated; 34.8 GiB closure, 2,846 store paths)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `1e53cd57-002a-45f4-b9cf-b5af10c2f946` (current), Antigravity `8325d2db-a1c0-486a-a517-ffea4b9620ed`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Added Foliate EPUB reader and configured EPUB MIME associations (Gen 129).
- [x] Declared `pkgs.foliate` in [`modules/suites/desktop/apps.nix`](file:///home/nnon/lunar-witches/modules/suites/desktop/apps.nix) (`suite-desktop-apps`) and associated `application/epub+zip` MIME type in system and Home Manager; updated inputs via `nix flake update` and activated Generation 129.
- [x] Hooked `home.activation.updatePi` into [`modules/suites/ai/pi-coding-agent.nix`](file:///home/nnon/lunar-witches/modules/suites/ai/pi-coding-agent.nix) to run `pi update --models` and `pi update --extensions` on system switch; activated Generation 128.
- [x] Migrated `llama-swap`, `mkServerCmd`, and local model configs to [`modules/suites/ai/local.nix`](file:///home/nnon/lunar-witches/modules/suites/ai/local.nix); streamlined [`modules/suites/ai/prose.nix`](file:///home/nnon/lunar-witches/modules/suites/ai/prose.nix).
- [x] Extracted `hardware.amdgpu.development` option in [`modules/hardware/gpu/amd.nix`](file:///home/nnon/lunar-witches/modules/hardware/gpu/amd.nix) for `rgp` and RADV trace variables; purged vendor leaks from [`modules/suites/development/default.nix`](file:///home/nnon/lunar-witches/modules/suites/development/default.nix).
- [x] Provisioned dynamic, self-elevating `amdgpu-reset` system utility in `hw-gpu-amd` and removed hardcoded alias from [`modules/users/nnon/shell.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/shell.nix).

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

40. **Refactored `llama-swap` with `mkServerCmd` & Set 192k Context (`594fadc`, `modules/suites/ai/prose.nix`):**
    - Extracted 16 shared ROCm/Strix Halo flags into reusable `mkServerCmd` generator (DRY refactor).
    - Set `agentic/lfm2.5-24b-a2b` context size to 192k (`--ctx-size 196608`), requiring ~1.06 GiB KV cache in `snc4`.
    - Activated Generation 126.
41. **Decoupled `cacheTypeK` & `cacheTypeV` in `mkServerCmd` (`231bc94`, `modules/suites/ai/prose.nix`):**
    - Supported independent Key and Value quantization in `mkServerCmd` generator with fallback to `cacheTypeKV`.
    - Prepared infrastructure for asymmetric SNC quantization (`snc4` Key + `snc8` Value).
42. **Decoupled Local AI Serving, Isolated AMD Devtools & Dynamic GPU Reset (`61377de`):**
    - Migrated `llama-swap`, `mkServerCmd`, and local models from `suite-ai-prose` to `suite-ai-local` ([`modules/suites/ai/local.nix`](file:///home/nnon/lunar-witches/modules/suites/ai/local.nix)).
    - Streamlined `suite-ai-prose` ([`modules/suites/ai/prose.nix`](file:///home/nnon/lunar-witches/modules/suites/ai/prose.nix)) to strictly manage SillyTavern UI.
    - Added `hardware.amdgpu.development` option in [`modules/hardware/gpu/amd.nix`](file:///home/nnon/lunar-witches/modules/hardware/gpu/amd.nix) for `rgp` and RADV trace variables; purged vendor leaks from [`modules/suites/development/default.nix`](file:///home/nnon/lunar-witches/modules/suites/development/default.nix).
    - Added dynamic, self-elevating `amdgpu-reset` system utility in `hw-gpu-amd` and removed hardcoded DRI alias from [`modules/users/nnon/shell.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/shell.nix).
    - Ran `nix flake update` and activated Generation 127.
43. **Automated Pi Extension & Model Updates on Activation (`c4ea763`, `modules/suites/ai/pi-coding-agent.nix`):**
    - Added `home.activation.updatePi` DAG hook to run `pi update --models` and `pi update --extensions` during Home Manager activation.
    - Preserved resilience with `|| true` and wrapped PATH with `extraPackages` (`nodejs`, `bun`).
    - Activated Generation 128.
44. **Added Foliate EPUB Reader & MIME Associations (`72c702c`, `suite-desktop-apps`):**
    - Classified Foliate as a daily desktop application under `flake.nixosModules.suite-desktop-apps` ([`modules/suites/desktop/apps.nix`](file:///home/nnon/lunar-witches/modules/suites/desktop/apps.nix)).
    - Registered `application/epub+zip` association to `com.github.johnfactotum.Foliate.desktop` at system-level and in Home Manager ([`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix)).
    - Ran `nix flake update` and switched to Generation 129.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
