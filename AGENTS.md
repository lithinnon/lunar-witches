# AI Agent Guidelines & Architecture Invariants

> Mandatory repository invariants and boundaries.

---

## 1. Repository Invariants

- **Stack:** NixOS 26.11 via `flake-parts` & `home-manager` on branch `master`.
- **AskPass Runner:** In non-login subshells or automation, prefix switch with `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass nh os switch /home/nnon/lunar-witches`.
- **Secrets & Spirit World Boundary:** All private infrastructure, personal SSH aliases, campus credentials, and SOPS encrypted tokens reside in the private companion repository / submodule `spirit-world` (`secrets/secrets.yaml`). Public `lunar-witches` contains zero secrets or raw tokens.
- **Submodule Workflow:** Commit and push changes inside `spirit-world/` first, then stage the updated pointer in `lunar-witches/`. Ensure GPG commit signing is preserved across both repositories.
- **Terminal Sandbox Boundary:** Antigravity IDE runs in a `bwrap` FHS container (`NoNewPrivs: 1`). Never run `nh os switch`, `test`, or `sudo` directly in its integrated terminal (kernel blocks setuid). Use an external host terminal or escape via `systemd-run --user --pty --same-dir nh os switch ...`.
- **Zero Backward-Compatibility Aliases:** Never preserve or create legacy aliases, shims, or compatibility bindings. Refactor all call sites directly and keep only canonical definitions.

---

## 2. Domain Placement ([ADR 0010](./retrospects/adr/0010-six-tier-dendritic-decomposition.md))

- **Windows Emulation:** Productivity tools (`bottles`) belong in `suites/desktop/apps.nix`; games (`steam`, `gamescope`) belong in `suites/gaming/`.
- **Hardware Limits:** Declare typed `lib.mkOption` in `modules/hardware/`; assign concrete values in `hosts/<host>/default.nix`.
- **Native Modules:** Configure upstream options directly using `lib.mkDefault` rather than wrapping them in custom options.
- **Full-Graph Convergence:** Verify changes across definition, aggregator, and consumer tiers with `nix build .#nixosConfigurations.lunar-qualia.config.system.build.toplevel --dry-run`.
- **Safe Editing:** Always use structured edit tools with unique surrounding anchors (no `sed`, `awk`, or line arithmetic).

---

## 3. Handover Protocol & Sliding Window

- **Start & Yield:** Read and update [`./HANDOFF.md`](./HANDOFF.md) on session start and yield.
- **Window Size:** Keep strictly the **last 3 completed milestones** in `HANDOFF.md` under `## 3. Recent Milestones`.
- **Graduation Rule:** When adding milestone $N$, cut any milestone $\le N - 3$ from `HANDOFF.md` and append it to `./retrospects/history/<YYYY-MM>-session-ledger.md` (create new monthly archive on month rollover).
- **Focus Sanitation:** `## 2. In-Flight Focus` tracks only active/pending tasks ($\le 4$ items). Once a milestone covers completed work, remove resolved `[x]` items.
- **Target Line Ceiling:** Keep `HANDOFF.md` strictly under 45 lines.
