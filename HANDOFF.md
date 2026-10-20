# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-20 14:41 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `7474f38`
- **Working Tree:** Clean (Ready for nh os switch)
- **Live NixOS Generation:** Generation 152 (Active; switching to Generation 153)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `9e11d61f-32ec-444c-a6a2-0f1837069929` (current), Antigravity `6a279548-478f-4fe9-a6a7-7b4d58ca9df7`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Integrated Hugging Face `git-xet` & Git LFS, updated flake inputs, fixed `radeon-developer-tool-suite` build with pinned patchelf 0.15.2, built and switching via `nh os switch`.
- [x] Declared `programs.git.lfs.enable = true` and `lfs."customtransfer.xet"` in `modules/users/nnon/development.nix`.
- [x] Added `pkgs.git-xet` to `home.packages`.
- [x] Updated flake inputs via `nix flake update`.
- [x] Fixed `radeon-developer-tool-suite` patchelf 0.19.2 assertion failure by pinning `patchelf 0.15.2` in `nativeBuildInputs`.
- [x] Built Generation 153 candidate cleanly via `nh os build`.
- [ ] Commit changes to Git `master`.
- [ ] Activate Generation 153 via `nh os switch`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35, 48, 51, 52):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

53. **Tuned Boulesis KV Cache Quantization & 96k Context Window (`fd7a0e1`, `6725e28`, `modules/suites/ai/local.nix`):**
    - Configured asymmetric SNC quantization (`cacheTypeK = "snc4"`, `cacheTypeV = "snc8"`) with 1024 `bf16` tail tokens.
    - Expanded context window from 64k to 96k (`ctxSize = 98304`, ~72,000 words); activated Generation 141.
54. **Renamed `beellama.cpp` to `triellama.cpp` & Added Vector Embedding Model (`pkgs/triellama`, `modules/suites/ai/local.nix`):**
    - Renamed in-tree derivation `pkgs/beellama` to `pkgs/triellama`, maintaining backward-compatible alias.
    - Configured `vector/embeddinggemma-2` in `llama-swap`; activated Generation 146.
55. **Configured `llama-swap` Groups & CPU Offloading for Embeddings (`07542e8`, `modules/suites/ai/local.nix`):**
    - Declared `groups` in `llama-swap`: `chat` (GPU pool) and `embeddings` (CPU pool).
    - Offloaded `vector/embeddinggemma-2` to 12 CPU threads; activated Generation 148.
56. **Allocated 1024 MiB RAM Cache Specifically to Boulesis (`modules/suites/ai/local.nix`):**
    - Parameterized `cacheRam ? null` in `mkServerCmd`; added `-cram 1024` to Boulesis in `extraFlags`.
    - Switched and activated Generation 150; validated `llama-swap.service`.
57. **Integrated Hugging Face `git-xet`, Git LFS & Pinned RDTS Patchelf (`modules/users/nnon/development.nix`, `pkgs/radeon-developer-tool-suite/default.nix`):**
    - Declared `programs.git.lfs.enable = true` and `lfs."customtransfer.xet"` agent in Home Manager.
    - Added `pkgs.git-xet` to `home.packages`.
    - Updated flake inputs (`chaotic`, `home-manager`, `nix-craftapps`, `nixpkgs`).
    - Fixed RDTS build failure under nixpkgs `patchelf 0.19.2` by pinning `patchelf 0.15.2` in `nativeBuildInputs` to avoid `Assertion 'splitIndex == -1' failed` on overlapping LOAD segments in `RadeonGPUAnalyzer-bin`.
    - Built candidate Generation 153 cleanly via `nh os build`.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
