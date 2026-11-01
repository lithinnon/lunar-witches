# Handover Ledger

> Read upon session start; update before yielding. Maintain sliding window of last 3 milestones (graduate older to [`./retrospects/history/<YYYY-MM>-session-ledger.md`](./retrospects/history/2026-10-session-ledger.md)). Keep strictly under 45 lines.

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-11-01 14:27 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `b614552`
- **Live Generation:** Generation 206

---

## 2. In-Flight Focus

- [ ] Empirically verify s2idle sleep/wake with DC IPS active.

---

## 3. Recent Milestones

93. **Powertop Auto-Tune & Idle-Class Syncthing Scheduling (`HEAD`):**
    - Enabled `powerManagement.powertop.enable = true` in `modules/roles/laptop.nix` (auto-tuning 21 idle PCIe endpoints to `power/control = auto`).
    - Configured `CPUSchedulingPolicy = "idle"`, `IOSchedulingClass = "idle"`, and `Nice = 19` on `syncthing.service` in `modules/features/syncthing.nix`.
    - Validated full-graph convergence dry run (`nixosConfigurations.lunar-qualia`).
94. **Open WebUI On-Demand, Zero-Polling & PyTorch Bypass (`HEAD`):**
    - Throttled scheduler/timer poll intervals to 86400s and disabled automations, eliminating 1s SQLite wakeups (0.0% idle CPU).
    - Set `RAG_EMBEDDING_ENGINE = "openai"` and bypassed retrieval, preventing in-process PyTorch loading (memory dropped from 983 MiB to ~298 MiB cgroup / 376 MiB RSS).
    - Converted to on-demand execution (`wantedBy = []`) with `Nice = 19` batch scheduling.
95. **Gamedev Suite, Privacy Isolation & Spirit World Integration (`HEAD`):**
    - Created `modules/suites/development/gamedev.nix` (`suite-development-gamedev`) with `godot_4` and `gdtoolkit_4`.
    - Isolated `retrospects` into dedicated branch and worktree; added MIT license.
    - Integrated private submodule `spirit-world` (`lithinnon/spirit-world`); purged secrets and personal SSH/wifi.
    - Socket-activated Open WebUI on port 11111 with 10m idle auto-stop (`systemd-socket-proxyd`) and secret injection.
    - Migrated private in-tree package derivation and overlay to `spirit-world` (`home.packages`).
    - Wired pre-commit dual-target convergence hook (`nixfmt-tree` & `lunar-qualia` + standalone fallback).
