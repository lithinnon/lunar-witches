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
98. **S2idle Root Cause Fixed Without Workaround (`347e27c`, ADR 0018):**
    - Firmware loses the SD reader's subsystem IDs in S0i3; `pciehp` removes it as replaced and blocks syncing the mounted card.
    - Added `pkgs/rtsx-subsystem-ids` to cache the post-S0i3 IDs at boot; removed the hook. Confirmed by T19 (card unmounted) and T20.
    - T20 (Tera mounted, no hook): 3/3 with 27-29s S0i3, no `pciehp` events, no remount.
99. **Add yt-dlp to Desktop Applications Suite (`1198798`):**
    - Declared `yt-dlp` in `modules/suites/desktop/apps.nix` (`suite-desktop-apps`).
    - Verified dual-closure full-graph convergence (`lunar-qualia` and `lunar-qualia-standalone`).
100. **Add Kafae Suite, Update Flake Inputs & Fix Derivations (`fb6d736`):**
    - Declared `suite-education-kafae` for CEDT Grader CLI (`kafae`).
    - Bumped flake inputs; patched upstream `opencode-node_modules` hash mismatch.
    - Resolved headless font test failures in `digital` and `digital-egro` by skipping tests.
101. **Add Hermes Agent Suite with TokenMe & Lunar-Witch Skin (`0527abb`):**
    - Declared `suite-ai-hermes` with custom `tokenme` provider (`https://api.tokenme.limited/api/v1/`).
    - Wired `TOKENME_API_KEY` and Desktop `sessionTokenFile` via `spirit-world` SOPS secrets.
    - Enabled user linger (`nnon`), installed `lunar-witch` skin, and switched to Gen 234.
102. **Integrate Matt Pocock Skills & Decommission OpenCode (`db548d0`):**
    - Packaged flattened `mattpocock-skills` derivation and wired shared module across AI suites.
    - Wrapped Antigravity packages with basic password-store and `SSH_TTY=/dev/null` keyring bypass.
    - Decommissioned `suite-ai-opencode` and removed OpenCode shell aliases; bumped spirit world.
103. **Flake Inputs Optimization, Brave Migration & AAGL Caching (`8d4712b`):**
    - Updated inputs, migrated Brave to Buckley310 flake, deduplicated home-manager and flake-parts trees.
    - Set up system-wide ezkea Cachix substituter and keys; dropped aagl rust-overlay follow to achieve 100% cache hits.
    - Added anime-game-launcher alongside honkers-launcher in suite-gaming; switched to Generation 238.
104. **Pi Suite Migration, DeepSeek Harness & Rust Hook Fixes (`e017582`):**
    - Replaced Hermes suite with `suite-ai-pi` and `suite-ai-deepseek-harness`; wired mattpocock skills.
    - Patched nixpkgs cargo-setup-hook missing buildInputs for codex, primp, and chromadb.
    - Authorized automatic switch in `AGENTS.md`; bumped spirit world; switched to Generation 254.
