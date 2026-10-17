# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-17 22:38 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `4ea655b`
- **Working Tree:** Clean (Generation 150 activated)
- **Live NixOS Generation:** Generation 150 (Activated; Linux 7.2.11-cachyos-lto-znver4, 35.0 GiB closure)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `6a279548-478f-4fe9-a6a7-7b4d58ca9df7` (current), Antigravity `b5499c38-6814-4f61-9a66-2b8434864721`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Configured `-cram 1024` specifically for Boulesis (`creative/boulesis-v2.1-headtune`) in `llama-swap` while retaining 0-RAM cache on other models; activated Generation 150.
- [x] Parameterized `cacheRam` and auto-detected cache-ram flags in `mkServerCmd` (`modules/suites/ai/local.nix`).
- [x] Added `-cram 1024` specifically to `creative/boulesis-v2.1-headtune`'s `extraFlags`.
- [x] Switched and activated Generation 150 via `nh os switch`.
- [x] Restarted and validated `llama-swap.service`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35, 48, 51):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

52. **Migrated SillyTavern to User-Level Service and `~/.local/share/SillyTavern` (`236a884`, `modules/suites/ai/prose.nix`, `modules/users/nnon/desktop.nix`):**
    - Migrated existing 66MB state from `/var/lib/SillyTavern` to `${XDG_DATA_HOME}/SillyTavern` (`~/.local/share/SillyTavern`), setting clean `nnon:users` ownership.
    - Preserved legacy state at `/var/lib/SillyTavern.bak`.
    - Refactored `suite-ai-prose` to disable system `services.sillytavern` and provision `systemd.user.services.sillytavern` via Home Manager.
    - Linked declarative drift-checked `config.yaml` to `~/.local/share/SillyTavern/config.yaml` via `xdg.dataFile`.
    - Updated Service Deck Plasma widget to control SillyTavern under `scope = "user"`, enabling zero-privilege toggling; activated Generation 138.
53. **Tuned Boulesis KV Cache Quantization & 96k Context Window (`fd7a0e1`, `6725e28`, `modules/suites/ai/local.nix`):**
    - Configured asymmetric SNC quantization (`cacheTypeK = "snc4"`, `cacheTypeV = "snc8"`) with 1024 `bf16` tail tokens.
    - Expanded context window from 64k to 96k (`ctxSize = 98304`, ~72,000 words) for balanced novel co-authoring capacity and high decode throughput; activated Generation 141.
54. **Renamed `beellama.cpp` to `triellama.cpp` & Added Vector Embedding Model (`pkgs/triellama`, `modules/suites/ai/local.nix`):**
    - Renamed in-tree derivation `pkgs/beellama` to `pkgs/triellama`, purging legacy `0.4.7` release versioning.
    - Maintained backward-compatible `beellama` alias in `pkgs/default.nix`.
    - Configured `vector/embeddinggemma-2` in `llama-swap`; activated Generation 146.
55. **Configured `llama-swap` Groups & CPU Offloading for Embeddings (`07542e8`, `modules/suites/ai/local.nix`):**
    - Declared `groups` in `llama-swap`: `chat` (GPU swap pool) and `embeddings` (CPU non-evicting pool).
    - Offloaded `vector/embeddinggemma-2` to 12 CPU threads (`--n-gpu-layers 0 --batch-size 8192 --ubatch-size 8192 --no-mmproj`), eliminating GPU context switching and VRAM overhead.
    - Enabled `--reasoning-preserve` for Boulesis (`creative/boulesis-v2.1-headtune`); activated Generation 148.
56. **Allocated 1024 MiB RAM Cache Specifically to Boulesis (`modules/suites/ai/local.nix`):**
    - Updated `mkServerCmd` in `modules/suites/ai/local.nix` to detect custom `-cram` / `--cache-ram` or parameterize `cacheRam ? null`, cleanly defaulting to `--cache-ram 0` without argument collisions.
    - Added `-cram 1024` to Boulesis (`creative/boulesis-v2.1-headtune`) in `extraFlags`, keeping `agentic/lfm2.5-24b-a2b` on 0-RAM NVMe-only spill.
    - Switched and activated Generation 150; restarted `llama-swap.service`.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.

