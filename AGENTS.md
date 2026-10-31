# AI Agent Guidelines & Architectural Invariants: `lunar-witches`

> **Scope:** Mandatory behavioral rules, code boundaries, and handover protocol for any AI agent operating in this repository. Read before inspecting or modifying any configuration.

---

## 1. System Identity & Core Invariants

- **Repository:** [`/home/nnon/lunar-witches`](file:///home/nnon/lunar-witches) | **Framework:** NixOS 26.11 (Zokor) via `flake-parts` & `home-manager` | **Branch:** `master`
- **Primary Host:** `lunar-qualia` (Check `~/.agents/devices/$(hostname).md` for hardware specs).

### Mandatory Rules
1. **Device Profiles:** Check hostname (`hostname`) and consult `~/.agents/devices/<hostname>.md` before making hardware, GPU, or memory recommendations.
2. **TTM Allocation:** Run `mem-ttm` to verify active VRAM/TTM limits before local model loading or heavy GPU allocations.
3. **Declarative NixOS Only:** Never suggest imperative package managers (`apt`, `dnf`, `rpm`) or bootloader tools (`grubby`). All state is declared in Nix and activated via `nh os switch`.
4. **Privilege Escalation:** Use `sudo -A` (graphical `ksshaskpass`). For `nh os switch` in non-login subshells or automation, prefix with `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass nh os switch /home/nnon/lunar-witches`.
5. **No Containers:** No `docker`/`podman`/`distrobox`. Sourced packages are managed in Flake/`pkgs/`, or run via plain `appimage-run`.
6. **Secrets Boundary:** Never commit secrets to `.nix` files or Git (`/nix/store` is world-readable). Secrets live in `chmod 600` files (`~/.config/secrets.env`) or encrypted via `sops-nix` (`secrets/secrets.yaml`).

---

## 2. Domain Placement & Architectural Guardrails

The repo follows a 6-tier dendritic tree (see [ADR 0010](retrospects/adr/0010-six-tier-dendritic-decomposition.md)). Adhere strictly to these boundaries:
- **Windows Emulation:** General productivity tools (`bottles`) belong in `suites/desktop/apps.nix`; games (`steam`, `gamescope`) belong in `suites/gaming/`.
- **Hardware Parameters:** Never hardcode machine limits in `modules/hardware/`. Expose typed `lib.mkOption` and define host values in `hosts/<host>/default.nix`.
- **Native Modules:** Avoid custom wrapper options around native NixOS services; configure upstream options directly with `lib.mkDefault`.
- **Full-Graph Convergence:** Changes across definition, aggregator, and consumer layers must evaluate end-to-end (`nix build --dry-run`) before declaring a task complete.
- **Safe Editing:** Never use `sed`, `awk`, or manual line arithmetic. Always use structured edit tools with unique surrounding anchor blocks.

---

## 3. Multi-Agent Continuity & Handover Protocol

To maintain zero amnesia across agent swaps and fresh sessions:

1. **Turn 1 Orientation (Every Session):**
   - Run `git status` and `git log -n 3 --oneline`.
   - Read [`HANDOFF.md`](file:///home/nnon/lunar-witches/HANDOFF.md) to inspect the active register, current commit, in-flight queue, and recent milestones.
   - For unfamiliar domains, look up authoritative references in [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md).
2. **Session Rotation / Handover Ceremony:**
   - Commit working code with a conventional commit.
   - Externalize discovered hardware quirks or architectural decisions into `retrospects/`.
   - Update `HANDOFF.md` active state header and provide a 1-line resume prompt: `"Resume from HANDOFF.md: <objective>"`.
3. **Sliding-Window Rule:**
   - `HANDOFF.md` must stay strictly under **~100 lines**.
   - Graduate completed milestones from `HANDOFF.md` to [`retrospects/history/2026-10-session-ledger.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-10-session-ledger.md).
