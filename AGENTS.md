# AI Agent Guidelines & Architecture Invariants

> Mandatory repository invariants and boundaries. Hardware specs live in `~/.agents/devices/$(hostname).md`; global system rules live in `~/.agents/AGENTS.md`.

---

## 1. Repository Invariants

- **Stack:** NixOS 26.11 via `flake-parts` & `home-manager` on branch `master`.
- **AskPass Runner:** In non-login subshells or automation, prefix switch with `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass nh os switch /home/nnon/lunar-witches`.
- **Secrets Boundary:** Stored in `chmod 600` `~/.config/secrets.env` or encrypted via `sops-nix` in `secrets/secrets.yaml`. Never commit raw tokens to `.nix` or git.

---

## 2. Domain Placement ([ADR 0010](./retrospects/adr/0010-six-tier-dendritic-decomposition.md))

- **Windows Emulation:** Productivity tools (`bottles`) belong in `suites/desktop/apps.nix`; games (`steam`, `gamescope`) belong in `suites/gaming/`.
- **Hardware Limits:** Declare typed `lib.mkOption` in `modules/hardware/`; assign concrete values in `hosts/<host>/default.nix`.
- **Native Modules:** Configure upstream options directly using `lib.mkDefault` rather than wrapping them in custom options.
- **Full-Graph Convergence:** Verify changes across definition, aggregator, and consumer tiers with `nix build .#nixosConfigurations.lunar-qualia.config.system.build.toplevel --dry-run`.
- **Safe Editing:** Always use structured edit tools with unique surrounding anchors (no `sed`, `awk`, or line arithmetic).

---

## 3. Handover Protocol

- Read and update [`./HANDOFF.md`](./HANDOFF.md) on session start and yield.
- Keep [`./HANDOFF.md`](./HANDOFF.md) strictly under 100 lines; graduate completed milestones to [`./retrospects/history/2026-10-session-ledger.md`](./retrospects/history/2026-10-session-ledger.md).
