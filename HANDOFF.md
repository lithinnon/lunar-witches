# Handover Ledger

> Read upon session start; update before yielding. Keep under 100 lines (graduate older milestones to [`./retrospects/history/2026-10-session-ledger.md`](./retrospects/history/2026-10-session-ledger.md)).

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-31 16:53 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `HEAD`
- **Live Generation:** Generation 197

---

## 2. In-Flight Focus

- [x] Unified AMD shells into `shells/amd/dev.nix` (`amd-dev`) and `shells/amd/runtime.nix` (`amd-runtime`).
- [x] Verified MMA computation under ROCm HIP and HRX, and tested NPU runtime (`pyxrt`) & Rust FFI to HIP.
- [x] Declaratively packaged HRX C/C++ runtime & direct DRM driver (`pkgs.hrx-runtime`) and purged `~/.local/share/rocm/hrx-system`.

---

## 3. Recent Milestones

81. **Purge Backward-Compatibility Aliases & Enforce Invariant (`2a77efd`, `8f8ce13`):**
    - Removed legacy aliases codebase-wide and enforced zero-alias invariant in `AGENTS.md`.
82. **Unify AMD DevShells into `amd-dev` & `amd-runtime` (`be04c99`):**
    - Replaced `standard.nix` and `loom.nix` with `dev.nix` (`amd-dev`) and `runtime.nix` (`amd-runtime`), unifying the entire ROCm, PyTorch, Flash Attention, XRT, Loom, HRX, and Rust toolchain into a single studio.
83. **Declarative HRX Runtime Package & Imperative Dir Purge (`HEAD`):**
    - Created `pkgs/hrx-runtime/default.nix` packaging `libhrx`, `libamdf`, `libamdhip64.so`, and `amdf-enumerate` with autoPatchelfHook.
    - Wired `pkgs.hrx-runtime` into `shells/amd/dev.nix`, `shells/amd/runtime.nix`, and `shells/amd/scripts.nix`.
    - Permanently purged imperative `~/.local/share/rocm/hrx-system` from disk.
