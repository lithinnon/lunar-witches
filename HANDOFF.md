# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.
>
> **Sliding Window Rule:** Keep this ledger under ~100 lines. Older completed work graduates to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-16 21:33 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `c0dfcc1`
- **Working Tree:** Clean (activated Generation 137)
- **Live NixOS Generation:** Generation 137 (Activated; Linux 7.2.11-cachyos-lto-znver4, 35.0 GiB closure)

### Indexed Knowledge Chronicles (Tier 3) & Cold Traces (Tier 4)
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md) (Synthesizes all 9 thematic domains from Pi & Antigravity sessions).
- **Cold Forensic Traces:** Antigravity `433164ee-129a-4175-a59a-01ec42156f61` (current), Antigravity `8d76ad0a-4bc9-454b-8a45-7e8ab17b1f3e`, Pi `01a13422-d88c-70d1-a404-d738cde6a7e2`.

---

## 2. In-Flight Focus & Immediate Queue

- **Current Focus:** Idle — awaiting next directive. Last closed: Integrated `sops-nix` secret management, declared `/run/secrets/hf_token`, removed unmanaged `secrets.env` shell sourcing, and updated flake inputs.
- [x] Declared `sops-nix` flake input and `self.nixosModules.feature-sops` trait.
- [x] Configured `.sops.yaml` and encrypted `secrets/secrets.yaml` with dual-recipient age identities.
- [x] Declared `sops.secrets."hf_token"` with mode `0400` owned by `nnon` in `hosts/lunar-qualia/default.nix`.
- [x] Migrated Fish and Bash in `modules/users/nnon/shell.nix` to load `/run/secrets/hf_token` and purged unmanaged `secrets.env`.
- [x] Switched and activated Generation 137 via `nh os switch`.

---

## 3. Active Subsystem Pointers

When working on active subsystems, consult these authoritative references:
- **Master Session Chronicles:** [`retrospects/history/2026-10-session-chronicles.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-chronicles.md)
- **AI Stack (ROCm, HRX, Loom, XRT, devshells):** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`modules/suites/ai/`](file:///home/nnon/lunar-witches/modules/suites/ai/)
- **Desktop & Digital Logic Config:** [`modules/users/nnon/desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix) & [`retrospects/troubleshooting/nixos-desktop-quirks.md`](file:///home/nnon/lunar-witches/retrospects/troubleshooting/nixos-desktop-quirks.md)
- **Master Knowledge Index:** [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)
- **Archived Milestones (Items 1–34):** [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md)

---

## 4. Recent Delta (Sliding Window: Last 5 Milestones)

47. **Resolved Flatpak CJK Font Rendering & Dangling Symlinks (`9a74358`, `bd99dc0`):**
    - Provisioned `/var/lib/flatpak/overrides/global` via `systemd.tmpfiles.rules` (`modules/suites/desktop/apps.nix`) granting `/nix/store:ro`.
    - Defined explicit CJK fallback prioritization (`fonts.fontconfig.defaultFonts`) in `modules/suites/desktop/fonts.nix`; activated Generation 132.
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
    - Updated flake inputs (`a64afa9`); fixed `age.keyFile = null` to prevent spurious `/var/lib/sops-nix/key.txt` activation failures (`c0dfcc1`).
    - Switched and activated Generation 137.

---

## 5. Architectural Invariants & Gotchas

1. **Privilege Escalation:** Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching (`ksshaskpass` graphical dialog).
2. **`gfx` Invariant:** `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture.
3. **TheRock Python Wheels:** Aggregate index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch packages split into neutral `torch` and device kernel pack `amd-torch-device-${gfx}`.
4. **Secrets Management:** Secrets live in encrypted `secrets/*.yaml` via `sops-nix` and decrypt to RAM in `/run/secrets/`. Do not commit plaintext tokens or private age keys to Git.
5. **Session Continuity:** Keep this file under 100 lines. Rotate completed entries into `retrospects/history/` regularly.
