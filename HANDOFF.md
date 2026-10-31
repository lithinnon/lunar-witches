# Handover Ledger

> Read upon session start; update before yielding. Keep under 100 lines (graduate older milestones to [`./retrospects/history/2026-10-session-ledger.md`](./retrospects/history/2026-10-session-ledger.md)).

---

## 1. Active State

- **Last Active Agent:** Antigravity (Gemini 3.8 Flash)
- **Timestamp:** 2026-10-31 17:35 +07:00
- **Host Target:** `lunar-qualia`
- **Active Git Commit:** `a797c5a`
- **Live Generation:** Generation 197

---

## 2. In-Flight Focus

- [x] Unified AMD shells into `shells/amd/dev.nix` (`amd-dev`) and `shells/amd/runtime.nix` (`amd-runtime`).
- [x] Declaratively packaged HRX C/C++ runtime & direct DRM driver (`pkgs.hrx-runtime`) and purged `~/.local/share/rocm/hrx-system`.
- [x] Replaced fragmented Python setup scripts with unified `init-venv` (`--torch`, `-fa`/`--flash-attn`, `--iron`) and Btrfs package reflink caching.
- [x] Streamlined `shells/amd/`: purged unused Bazel tools (`bazelisk`, `bazel_7`) and removed redundant banner state.

---

## 3. Recent Milestones

82. **Unify AMD DevShells into `amd-dev` & `amd-runtime` (`be04c99`):**
    - Replaced `standard.nix` and `loom.nix` with `dev.nix` (`amd-dev`) and `runtime.nix` (`amd-runtime`), unifying the entire ROCm, PyTorch, Flash Attention, XRT, Loom, HRX, and Rust toolchain into a single studio.
83. **Declarative HRX Runtime Package & Imperative Dir Purge (`a8a818e`):**
    - Created `pkgs/hrx-runtime/default.nix` packaging `libhrx`, `libamdf`, `libamdhip64.so`, and `amdf-enumerate` with autoPatchelfHook.
    - Wired `pkgs.hrx-runtime` into `shells/amd/dev.nix`, `shells/amd/runtime.nix`, and `shells/amd/scripts.nix`.
    - Permanently purged imperative `~/.local/share/rocm/hrx-system` from disk.
84. **Unified `init-venv` & Decoupled Package Caching (`0e4c0a5`):**
    - Consolidated `init-rocm-venv`, `build-flash-attention`, and `init-iron-venv` into canonical `init-venv` with `--torch`, `-fa`/`--flash-attn`, and `--iron` flags.
    - Decoupled package cache (`~/.local/share/rocm/pkg-cache-${gfx}`) from virtualenvs: `init-venv` uses Btrfs reflink copy (`--reflink=auto`) to seed 6.6GB packages into clean project-local `./.venv` in under 0.5s.
    - Removed global venv auto-activation from `common.nix` (strictly project-local `./.venv` activation).
85. **Pruned Bazel & Streamlined AMD Devshell (`2e03656`):**
    - Removed unused build tools `bazelisk` and `bazel_7` from `shells/amd/dev.nix`.
    - Removed redundant `(Active Venv: ...)` output from devshell startup banner.
86. **Refactored `pkgs/` & Enforced Repository Invariants (`HEAD`):**
    - Single-sourced in-tree package set across `perSystem.packages` and `flake.overlays.default` via `inTreePackages` map, eliminating boilerplate duplication.
    - Enforced Zero Backward-Compatibility rule: purged legacy aliases `amd-ttm`, `beellama`, `rdts`, `rgp`, `radeon-gpu-profiler`, and `loom`.
    - Refactored call sites: updated `modules/hardware/gpu/amd.nix` to canonical `pkgs.radeon-developer-tool-suite`, removed `ln -s amd-ttm` from `pkgs/mem-ttm`, updated `modules/suites/ai/rocm.nix` to call `pkgs.rocm-therock` directly, and updated `shells/amd/` to prefer `pkgs.*` with fallback.
    - Added `rocm-therock-gfx1151` to `packages` for direct CLI evaluation and build.
