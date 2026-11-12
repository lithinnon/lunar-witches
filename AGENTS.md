# AI Agent Guidelines & Architecture Invariants

> Mandatory repository invariants and boundaries.

---

## 1. Repository Invariants

- **Stack:** NixOS 26.11 via `flake-parts` & `home-manager` on branch `master`.
- **AskPass Runner:** In non-login subshells or automation, prefix switch with `NH_SUDO_ASKPASS=/run/current-system/sw/bin/conduct nh os switch /home/nnon/lunar-witches`.
- **Machine-Readable nh CLI:** Automated agents should pass `--json` to `nh` commands (`nh os build /home/nnon/lunar-witches --json`, `nh os switch ... --json`, `nh os build --dry --json`) for structured, parseable evaluation and deployment outputs.
- **Secrets & Spirit World Boundary:** All private infrastructure, personal SSH aliases, campus credentials, private packages, and SOPS encrypted tokens reside in `spirit-world` (`secrets/secrets.yaml`). Public `lunar-witches` contains zero secrets or raw tokens.
- **Submodule Workflow & Redaction:** Commit and push changes inside `spirit-world/` first, then stage pointer in `lunar-witches/` preserving GPG signing. Publicly from the main repo (commits, logs, `HANDOFF.md`), any changes in `spirit-world` must be strictly redacted—report only as `"bump spirit world"` with zero internal package names, hashes, or details exposed.
- **Retrospects Worktree:** Documentation, ADRs, and session ledgers reside on branch `retrospects`, mounted at `./retrospects` via `git worktree add retrospects retrospects`. Commit and sign documentation changes within `./retrospects` on branch `retrospects`.
- **Automated Switch Execution:** The agent is authorized to execute system switches automatically without manual user confirmation once builds pass, using `env NH_SUDO_ASKPASS=/run/current-system/sw/bin/conduct nh os switch /home/nnon/lunar-witches --json` (triggers context-aware `conduct`).
- **Zero Backward-Compatibility Aliases:** Never preserve or create legacy aliases, shims, or compatibility bindings. Refactor all call sites directly and keep only canonical definitions.
- **Bespoke Tooling & Low-Power Invariants ([ADR 0019](./retrospects/adr/0019-bespoke-engineering-and-low-power-daemon-invariants.md)):** When a desired system feature does not exist upstream or direct packages are blind/unsuitable for autonomous agent workflows, engineer declarative in-house tooling (such as `conduct`). All bespoke daemons must strictly adhere to power-efficiency invariants: zero idle timer wakeups (allowing deep package C-states C8/C10), purely event-driven kernel syscalls (blocking inotify/epoll/netlink, no polling/sleep loops), minimal resident memory footprint (<1MB RSS, zero GC), and seamless native integration without imperative wrapper scripts.

---

## 2. Domain Placement ([ADR 0010](./retrospects/adr/0010-six-tier-dendritic-decomposition.md))

- **Windows Emulation:** Productivity tools (`bottles`) belong in `suites/desktop/apps.nix`; games (`steam`, `gamescope`) belong in `suites/gaming/`.
- **Hardware Limits:** Declare typed `lib.mkOption` in `modules/hardware/`; assign concrete values in `hosts/<host>/default.nix`.
- **Native Modules:** Configure upstream options directly using `lib.mkDefault` rather than wrapping them in custom options.
- **Full-Graph Convergence:** Verify changes across definition, aggregator, and consumer tiers with `nh os build --dry` (or `nh os build --dry --json`) or `nh os switch --dry`.
- **Safe Editing:** Always use structured edit tools with unique surrounding anchors (no `sed`, `awk`, or line arithmetic).

---

## 3. Handover Protocol & Sliding Window

- **Start & Yield:** Read and update [`./HANDOFF.md`](./HANDOFF.md) on session start and yield.
- **Window Size:** Keep strictly the **last 3 completed milestones** in `HANDOFF.md` under `## 3. Recent Milestones`.
- **Graduation Rule:** When adding milestone $N$, cut any milestone $\le N - 3$ from `HANDOFF.md` and append it to `./retrospects/history/<YYYY-MM>-session-ledger.md` (create new monthly archive on month rollover).
- **Focus Sanitation:** `## 2. In-Flight Focus` tracks only active/pending tasks ($\le 4$ items). Once a milestone covers completed work, remove resolved `[x]` items.
- **Target Line Ceiling:** Keep `HANDOFF.md` strictly under 45 lines.
