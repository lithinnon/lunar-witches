# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-17 01:05 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `236a884`
- **Working Tree:** Clean (activated Generation 138)
- **Live NixOS Generation:** Generation 138 (Activated; Linux 7.2.11-cachyos-lto-znver4, 35.0 GiB closure)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `cbae2d67-98dd-4370-9c9a-84b2abf37b08` (current), Antigravity `433164ee-129a-4175-a59a-01ec42156f61`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Migrated SillyTavern to user-level service (`sillytavern.service`) with state fully in `~/.local/share/SillyTavern`, updated Service Deck Plasma widget to user scope, and activated Generation 138.
- [x] Migrated existing SillyTavern state (~66 MB) from `/var/lib/SillyTavern` to `~/.local/share/SillyTavern` with `nnon:users` ownership.
- [x] Renamed legacy `/var/lib/SillyTavern` to `/var/lib/SillyTavern.bak`.
- [x] Refactored `suite-ai-prose` (`modules/suites/ai/prose.nix`) to disable system `services.sillytavern` and provision `systemd.user.services.sillytavern` via Home Manager.
- [x] Symlinked declarative `config.yaml` to `~/.local/share/SillyTavern/config.yaml` via `xdg.dataFile`.
- [x] Updated `modules/users/nnon/desktop.nix` Service Deck widget to `scope = "user"`, eliminating Polkit prompts.
- [x] Switched and activated Generation 138 via `nh os switch`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–35):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

48. **Purged Obsolete `--cache-reuse` Flag from `llama-swap` Runner (`2b02c5f`, `modules/suites/ai/local.nix`):**
    - Removed obsolete `--cache-reuse 256` flag following `beellama.cpp` argument parser refactor (`7db0738a`); activated Generation 135.
49. **Added `pkgs.openssl` to AI DevShells (`b256b4a`, `shells/loom.nix`, `shells/rocm.nix`):**
    - Added OpenSSL headers/libraries to both package sets and runtime `LD_LIBRARY_PATH` in `torch-dev` and `loom-dev`.
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

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
