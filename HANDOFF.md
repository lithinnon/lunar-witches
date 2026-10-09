# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity (following Pi / MiMo v2.6)
- **Timestamp:** 2026-10-09 11:20 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `9fefc91` (`refactor(suites): write the llama-swap config as nix, render as yaml`)
- **Working Tree:** Clean (all changes committed)
- **Live NixOS Generation:** Generation 101 (`nh os switch` active, 0 drift)

---

## 2. Recent Work & Context

### Completed by Pi (MiMo v2.6):
1. **Added `llama-swap` to Prose Suite (`647c5a4`):** Packaged `llama-swap` alongside `llama-cpp-vulkan` in `modules/suites/ai/prose.nix`.
2. **Configured XDG Skeleton & Boulesis Model (`c3f42ef`, `77dccde`):** Declared `creative/boulesis-v2.1-headtune` with `ttl=1200s`, Vulkan0 compute device, and DeepSeek reasoning flags.
3. **User Service & AI Service Deck (`a0f5759`):** Wired `llama-swap.service` into user systemd units and registered it on the AI Service Deck group.
4. **Refactored Config to Typed Nix (`9fefc91`):** Converted raw text YAML into `pkgs.formats.yaml` generated from typed Nix attributes.

### Completed by Antigravity:
1. **Desktop Shortcuts & Utilities:** Installed `kcalc` (`kdePackages.kcalc`), fixed `LocalSend.desktop` shortcut (`Meta+Shift+L`), configured `Kate` (`Meta+Shift+Q`), `KCalc` (`Meta+Shift+D`), and `Google Calendar` (`Meta+Shift+C` via `xdg-open`).
2. **Bottles Stability:** Silenced unsupported environment popup and resolved component update runner binding.
3. **Multi-Agent Protocol:** Established this shared handover board and codified the handover contract into `AGENTS.md`.

---

## 3. In-Flight Tasks & Next Immediate Steps

- [x] Integrate `llama-swap` into `suite-ai-prose` (Completed by Pi / MiMo).
- [x] Establish bidirectional handover protocol (Completed by Antigravity).
- [ ] *(Pending user instruction)*: Awaiting next configuration goal from the user.

---

## 4. Architectural Notes & Gotchas for the Incoming Agent

1. **Privilege Escalation:**
   Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching. The system uses KDE Plasma's `ksshaskpass` graphical dialog.
2. **Desktop Application Shortcuts:**
   In KDE Plasma 6 Wayland, `.desktop` launch shortcuts in `kglobalshortcutsrc` live under `[services][<desktop-file-name>]` (e.g. `[services][LocalSend.desktop]`, `[services][google-calendar.desktop]`). Calling `qdbus org.kde.KWin /KWin org.kde.KWin.reconfigure` applies shortcut updates live to KWin's compositor key grabber.
3. **Llama-Swap Service:**
   Runs as a user systemd service listening strictly on loopback `127.0.0.1:8080`.
