# Handover Ledger

> Read upon session start; update before yielding. Keep under 100 lines (graduate older milestones to [`./retrospects/history/2026-10-session-ledger.md`](./retrospects/history/2026-10-session-ledger.md)).

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-31 15:25 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `2a77efd`
- **Live Generation:** Generation 197

---

## 2. In-Flight Focus

- [x] Ported VS Code settings to `~/.antigravity-ide/User/` (`settings.json`, `mcp.json`) and shared extensions.
- [x] Added Rust toolchain (`rustc`, `cargo`, `rust-analyzer`) and `RUST_SRC_PATH` to `shells/loom.nix`.
- [x] Streamlined top-level documentation, removed common-sense fluff, and converted all references to relative paths.
- [x] Extracted shared ROCm foundation (`mkCommonRocm`) into `shells/common-rocm.nix` and refactored `shells/rocm.nix` and `shells/loom.nix`.
- [x] Added declarative `pkgs.hrx-loom` (Loom SDK v0.1.0) and integrated into `loom-dev` shell.
- [x] Organized AMD devShells into `shells/amd/` and extracted raw shell scripts into `shells/amd/scripts.nix`.
- [x] Canonicalized AMD devShell names to `standard-dev`/`standard` and `loom-dev`/`loom`.

---

## 3. Recent Milestones

79. **Declarative Loom SDK v0.1.0 Packaging & Integration (`50ffc8c`):**
    - Created `pkgs/hrx-loom` with patchelfed `loom-compile`, `loom-serve`, `libloomc`, `libiree`, and Python site-packages. Added to `loom-dev` shell without manual CMake build requirements.
80. **Reorganize AMD Shells & Extract Scripts (`453e3a0`):**
    - Moved shells to `shells/amd/` (`common.nix`, `standard.nix`, `loom.nix`, `default.nix`) and extracted embedded shell scripts into `shells/amd/scripts.nix`.
81. **Canonicalize AMD Shell Names (`2a77efd`):**
    - Renamed primary/runtime devShells to `standard-dev`/`standard` and `loom-dev`/`loom` while maintaining backward-compatible aliases (`amd-ai-dev`, `hip-runtime`, `loom-runtime`).
