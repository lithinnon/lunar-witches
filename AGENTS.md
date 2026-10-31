# AI Agent Guidelines & Architecture Manual: `lunar-witches`

> **Note for AI Agents & Autonomous Coders:**  
> This file is the primary orientation and architectural reference for this repository. Read this file before inspecting or modifying any configuration. All contributions must adhere strictly to the invariants, conventions, and dendritic composition patterns outlined below.

---

## 1. System Identity & Core Invariants

- **Repository:** [`/home/nnon/lunar-witches`](file:///home/nnon/lunar-witches) | **Framework:** NixOS 26.11 (Zokor) via `flake-parts` & `home-manager` | **Branch:** `master`
- **Primary Host:** `lunar-qualia` (ASUS TUF Gaming A14 FA401EA, AMD Strix Halo APU, 32GB LPDDR5X UMA).

### Mandatory Rules
1. **Host Profiles:** Check hostname (`hostname`) and read hardware/swap profile at `~/.agents/devices/<hostname>.md` before hardware recommendations.
2. **TTM Allocation:** Run `mem-ttm` to verify active VRAM/TTM limits before local model loading or heavy GPU allocations.
3. **Declarative NixOS Only:** Never suggest imperative package managers (`apt`, `dnf`, `rpm`) or bootloader tools (`grubby`). All state is declared in Nix and activated via `nh os switch`.
4. **Privilege Escalation:** Use `sudo -A` (graphical `ksshaskpass`). For `nh os switch`, prefix with `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass nh os switch /home/nnon/lunar-witches` in non-login shells.
5. **No Containers:** No `docker`/`podman`/`distrobox`. Software is packaged in Flake, `pkgs/`, or run via plain `appimage-run`.
6. **Secrets Boundary:** Never commit secrets to `.nix` files or Git (`/nix/store` is world-readable). Secrets live in `chmod 600` files (`~/.config/secrets.env`) or encrypted via `sops-nix` (`secrets/secrets.yaml`).

---

## 2. Dendritic Structure & Domain Placement

The repo uses a 6-tier decoupled dendritic tree (see [ADR 0010](retrospects/adr/0010-six-tier-dendritic-decomposition.md)):
- `modules/core/`: Universal foundation (Nix, nh, sudo, locale, nix-ld). Zero GUI/hardware assumptions.
- `modules/roles/`: Form-factor roles (`laptop`, `desktop`, `server`, `boot-systemd`).
- `modules/hardware/`: CPU microcode, GPU drivers, zswap, Wi-Fi, OEM platform traits.
- `modules/features/`: Opt-in daemons (`amdgpu-boost`, `sops`, `syncthing`, `chulawifi`, `openssh`).
- `modules/suites/`: Curated software suites (`plasma`, `apps`, `gaming`, `ai`, `development`).
- `modules/users/`: Declarative Home Manager user profile (`users/nnon/`).
- `hosts/<host>/`: Host leaf composition (`default.nix`) and partition manifest (`hardware.nix`). (See [Adding Hosts Manual](retrospects/manuals/adding-hosts.md)).
- `pkgs/`: In-tree derivations & overlays (`mem-ttm`, `amdgpu-boost`, `app`, plasma widgets).
- `shells/`: Reusable devShells (`default`, `amd-ai-dev`, `loom-dev`).

### Key Domain Boundaries
- **Windows Tools:** General emulation (`bottles`) belongs in `suites/desktop/apps.nix`; games (`steam`, `gamescope`) belong in `suites/gaming/`.
- **Hardware Parameters:** Never hardcode machine limits in `modules/hardware/`. Expose typed `lib.mkOption` and set values in `hosts/<host>/default.nix`.
- **Native Modules:** Avoid wrapper options around native NixOS services; configure upstream services directly with `lib.mkDefault`.
- **Full-Graph Convergence:** Changes across definition, aggregator, and consumer layers must evaluate end-to-end (`nix build --dry-run`) before completing.
- **Safe Editing:** Never use `sed`/`awk`/line arithmetic. Always use dedicated structured edit tools with unique surrounding anchors.

---

## 3. Daily Operations & Verification

```bash
nix fmt                                                                             # Format syntax
nix build .#nixosConfigurations.lunar-qualia.config.system.build.toplevel --dry-run  # Dry-run evaluation
nh os build /home/nnon/lunar-witches                                                # Build & cache generation
nh os switch /home/nnon/lunar-witches                                               # Activate system configuration
nh clean all --keep 3                                                               # Clean old generations
```

---

## 4. Multi-Agent Continuity & Handover Protocol (Antigravity ↔ OpenCode)

1. **Memory Hierarchy:**
   - **Active Register:** [`HANDOFF.md`](file:///home/nnon/lunar-witches/HANDOFF.md) — sliding window strictly capped at **<100 lines**.
   - **Knowledge Base:** [`retrospects/`](file:///home/nnon/lunar-witches/retrospects/) (indexed in [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md)) for ADRs, proofs, and manuals.
   - **Cold Forensics:** Archived logs in `retrospects/history/` and raw `.jsonl` traces on disk.
2. **Turn 1 Orientation (Every Session):**
   - Run `git status` and `git log -n 3 --oneline`.
   - Read `HANDOFF.md` to identify active agent, lineage, immediate queue, and subsystem references.
3. **Session Rotation / Handover Ceremony:**
   - Commit working code with a conventional commit.
   - Externalize discovered hardware quirks or decisions into `retrospects/`.
   - Graduate completed milestones from `HANDOFF.md` to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md) to keep `HANDOFF.md` <100 lines.
   - Update `HANDOFF.md` active state header and provide resume prompt: `"Resume from HANDOFF.md: <objective>"`.
4. **Tool Strengths:**
   - **Antigravity:** Architectural refactors, multi-agent decomposition, multimodal UI verification, complex Flake modules.
   - **OpenCode (Qwen 3.8 26B-A4B):** Terminal iterations, localized module adjustments, TUI workflows, subagents, swift parameter tweaking.
