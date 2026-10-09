# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity
- **Timestamp:** 2026-10-09 12:21 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `ddcfe93` (`refactor(ai): eliminate hardcoded ROCm and package version strings`)
- **Working Tree:** Clean (all changes committed)
- **Live NixOS Generation:** Generation 101 (`nh os switch` candidate built and ready at `/nix/store/36czw5w052qik5z4kmvcwaxkvmgz2g5i-nixos-system-lunar-qualia-26.11.20261006.151fa4e`)

---

## 2. Recent Work & Context

### Completed by Pi (MiMo v2.6):
1. **Added `llama-swap` to Prose Suite (`647c5a4`):** Packaged `llama-swap` alongside `llama-cpp-vulkan` in `modules/suites/ai/prose.nix`.
2. **Configured XDG Skeleton & Boulesis Model (`c3f42ef`, `77dccde`):** Declared `creative/boulesis-v2.1-headtune` with `ttl=1200s`, Vulkan0 compute device, and DeepSeek reasoning flags.
3. **User Service & AI Service Deck (`a0f5759`):** Wired `llama-swap.service` into user systemd units and registered it on the AI Service Deck group.
4. **Refactored Config to Typed Nix (`9fefc91`):** Converted raw text YAML into `pkgs.formats.yaml` generated from typed Nix attributes.

### Completed by Antigravity:
1. **ROCm 10.1 (TheRock) In-Tree Derivation (`pkgs/rocm-therock`):**
   - Packaged AMD's official stable 10.1.0 prebuilts from `https://stable.repo.amd.com/rocm/core/tarball/`.
   - **GFX-Agnostic with Strict Enforcement:** `gfx` has **no default value** and throws an explicit error if omitted.
   - Built with `autoPatchelfHook`, linking `glibc`, `libstdc++`, `elfutils`, `numactl`, `libdrm`, and `libtool`.
   - Injected CRT objects, include dirs, and library rpaths into `rocm.cfg` and `amdclang++.cfg` so `hipcc` and `amdclang++` compile out-of-the-box with zero extra include or library flags. Tested and verified on hardware (`Kernel result = 1337`).
2. **Capability Suite Integration (`modules/suites/ai/rocm.nix`):**
   - Added typed module option `suites.ai.rocm.gfx` (strictly asserted, no default).
   - Injected ROCm into `environment.systemPackages` and `programs.nix-ld.libraries` (so unpatched Python wheels and binaries find `libamdhip64.so` system-wide without devshells).
   - Exposed system session variables (`ROCM_PATH`, `HIP_PATH`, `CMAKE_PREFIX_PATH`, `AMD_COMGR_CACHE_ENABLE`, `ROCFFT_KERNEL_CACHE_ENABLE`, `FLASH_ATTENTION_TRITON_AMD_ENABLE`).
3. **Three Squashed `nix develop` DevShells & Live Hardware Validation:**
   - **`hip-runtime` (`.#hip-runtime`):** Minimal execution and hardware verification shell (`rocminfo`, `rocm-smi`, runtime libraries).
   - **`hip-dev` (`.#hip-dev`):** Pure C++/HIP development environment (`hipcc`, `amdclang++`, `cmake`, `ninja`, `pkg-config`, `gcc`, `make`, full CMake package targets in `lib/cmake`).
   - **`torch-dev` (`.#torch-dev`):** Unified PyTorch AI environment with `libstdc++` and system runtime libs in `LD_LIBRARY_PATH`.
   - **Hardware Validation of Flash Attention 2 on Radeon 8060S (`gfx1151`):**
     - Bootstrapped test venv via `init-rocm-venv` with locked `torch==2.12.0+rocm10.1.0`, `triton==3.8.0+git669b31ac.rocm10.1.0`, and `amd-torch-device-gfx1151==2.12.0+rocm10.1.0`.
     - Built and installed `amd-aiter` and `flash-attention` with AITER Triton/CK backend.
     - Executed live Python validation script:
       `from flash_attn import flash_attn_qkvpacked_func, flash_attn_func`
       Executed both standard QKV and packed QKV forward passes on the GPU with full finite output (`True`) and zero crashes.
   - Exported `flake.lib.mkRocmDevShells` to allow instantiating shells for any GPU architecture.
4. **Host Leaf Composition (`hosts/lunar-qualia/default.nix`):**
   - Configured `suites.ai.rocm.enable = true; suites.ai.rocm.gfx = "gfx1151";`.
   - Verified dry-run evaluation and built generation locally via `nh os build`.

---

## 3. In-Flight Tasks & Next Immediate Steps

- [x] Integrate `pkgs/rocm-therock` (GFX-agnostic, strictly un-defaulted `gfx`).
- [x] Create 3 squashed devShells (`hip-runtime`, `hip-dev`, `torch-dev`) with anti-drift constraints and Flash Attention helpers.
- [x] Wire `suite-ai-rocm` into `lunar-qualia` and test local build (`nh os build`).
- [ ] *(Optional / Next)*: Activate live system generation via `nh os switch` (prompts via `ksshaskpass`).

---

## 4. Architectural Notes & Gotchas for the Incoming Agent

1. **Privilege Escalation:**
   Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching. The system uses KDE Plasma's `ksshaskpass` graphical dialog.
2. **`gfx` Strict Invariant:**
   `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture. If invoked without an explicit architecture string, it throws an error / fails assertion by design.
3. **Python & Wheel Resolution:**
   The official TheRock aggregate wheel index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch wheels in TheRock are split: `torch` is architecture-neutral host code, while `amd-torch-device-${gfx}` carries the GPU kernel packs. In `torch-dev`, `PIP_CONSTRAINT` / `UV_CONSTRAINT` prevents third-party packages from replacing ROCm packages with PyPI CPU wheels.
