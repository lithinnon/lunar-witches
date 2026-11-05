# Historical Session Ledger Archive (November 2026)

> **Context:** This archive captures completed technical milestones, packaging efforts, and hardware proofs graduated from [`HANDOFF.md`](../../HANDOFF.md).

---

## 1. Session Lineage

95. **Gamedev Suite, Privacy Isolation & Spirit World Integration (`eb77839`):**
    - Added `godot_4` and `gdtoolkit_4`; isolated `retrospects` into dedicated branch and worktree.
    - Integrated companion submodule `spirit-world` (`lithinnon/spirit-world`); purged secrets.
    - Socket-activated Open WebUI on port 11111 with 10m idle auto-stop; added dual-closure pre-commit.
96. **Package Hash Upstream Audit & Submodule Sync (`17113da`):**
    - Audited fixed hashes across all in-tree packages (`rocm-therock`, `xrt-amdxdna`, `hrx-runtime`, `hrx-loom`, `radeon-developer-tool-suite`, `digital-egro`); verified all up-to-date.
    - Bump spirit world.
    - Verified dual-closure full-graph system convergence (`lunar-qualia` and `lunar-qualia-standalone`).
97. **S2idle Resume Hang Workaround with IPS On (`e53f928`, ADR 0018):**
    - Traced the wake freeze to `rtsx_pci` via `pm_trace`; hook kept the driver out of the first real S0i3 of each boot.
    - Removed `disableDcIps` (`0x800` never reached S0i3); flashed BIOS 308. T17 and T18 (lid): 3/3 each with 10-33s S0i3.
    - Post-sleep stutter gone with VRR Never on `eDP-1`, persisted in `~/.config/kwinoutputconfig.json`, not in repo.
