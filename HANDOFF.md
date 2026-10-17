# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-17 21:08 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `100cf81`
- **Working Tree:** Clean (Generation 146 activated)
- **Live NixOS Generation:** Generation 146 (Activated; Linux 7.2.11-cachyos-lto-znver4, 35.0 GiB closure)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `b5499c38-6814-4f61-9a66-2b8434864721` (current), Antigravity `c7c91dd3-f90b-4585-8d1a-178f5b2302d4`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Renamed in-tree `beellama.cpp` to unversioned `triellama.cpp`, declared `vector/embeddinggemma-2` in `llama-swap`, switched to Generation 146. Awaiting `triellama.cpp` upstream backport of `gemma-embedding2` architecture.
- [x] Renamed `pkgs/beellama` to `pkgs/triellama`, removed legacy release `0.4.7` versioning, added backward-compatible alias.
- [x] Configured `vector/embeddinggemma-2` in `llama-swap` (`--embedding`, `--pooling mean`, `--embd-normalize 2`, 8k ctx, 2048 batch).
- [x] Evaluated, built, and activated Generation 146 via `nh os switch`.
- [x] Restarted `llama-swap.service` and verified active configuration in `~/.config/llama-swap.yml`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35, 48):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

50. **Added `vscode-clangd` Extension to VS Code Profile (`f6c9314`, `modules/users/nnon/development.nix`):**
    - Declared `llvm-vs-code-extensions.vscode-clangd` in default VS Code extensions for C/C++ language server support; activated Generation 136.
51. **Integrated `sops-nix` Declarative Secret Management (`2d43b1f`, `a64afa9`, `c0dfcc1`):**
    - Introduced `self.nixosModules.feature-sops` trait in `modules/features/sops.nix`, using host SSH ed25519 key (`/etc/ssh/ssh_host_ed25519_key`) converted to age via `ssh-to-age`.
    - Configured `.sops.yaml` with dual age recipients (`admin_nnon`, `admin_ssh`, and `host_lunar_qualia`).
    - Created `secrets/secrets.yaml` with encrypted `hf_token`, decrypted to `/run/secrets/hf_token` (`0400` owned by `nnon`).
    - Purged unmanaged `~/.config/secrets.env` logic from `fish.shellInit` and `bash.initExtra` in `modules/users/nnon/shell.nix`, migrating shells to read `/run/secrets/hf_token`.
    - Switched and activated Generation 137.
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
    - Configured `vector/embeddinggemma-2` in `llama-swap` (`--embedding`, `--pooling mean`, `--embd-normalize 2`, 8k ctx, 2048 batch size).
    - Switched and activated Generation 146; restarted `llama-swap.service`.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
