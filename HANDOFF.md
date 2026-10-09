# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity
- **Timestamp:** 2026-10-09 18:45 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `0437019` (`feat(ai): integrate xrt-amdxdna in-tree package, unlimited memlock, and unified rocm devshell`)
- **Working Tree:** Clean (all changes committed)
- **Live NixOS Generation:** Generation 101 (`nh os build` dry-run evaluated and ready)

---

## 2. Recent Work & Context

### Completed by Pi (MiMo v2.6):
1. **Added `llama-swap` to Prose Suite (`647c5a4`):** Packaged `llama-swap` alongside `llama-cpp-vulkan` in `modules/suites/ai/prose.nix`.
2. **Configured XDG Skeleton & Boulesis Model (`c3f42ef`, `77dccde`):** Declared `creative/boulesis-v2.1-headtune` with `ttl=1200s`, Vulkan0 compute device, and DeepSeek reasoning flags.
3. **User Service & AI Service Deck (`a0f5759`):** Wired `llama-swap.service` into user systemd units and registered it on the AI Service Deck group.
4. **Refactored Config to Typed Nix (`9fefc91`):** Converted raw text YAML into `pkgs.formats.yaml` generated from typed Nix attributes.

### Completed by Antigravity:
1. **ROCm 10.1 (TheRock) In-Tree Derivation (`pkgs/rocm-therock`):**
   - Packaged AMD's official stable prebuilts with overridable `version ? "10.1.0"` and strictly required `gfx`.
   - Injected CRT objects, include dirs, and library rpaths into `rocm.cfg` and `amdclang++.cfg` for zero-flag compilation.
2. **Capability Suite Integration (`modules/suites/ai/rocm.nix`):**
   - Generalized all version strings (`version`, `torchVersion`, `tritonVersion`) dynamically derived from `rocmPkg.version`.
   - Injected ROCm into `environment.systemPackages` and `programs.nix-ld.libraries` for unpatched binaries and wheels.
3. **Pattern B Shared Virtual Environment (`~/.local/share/rocm/venv-${gfx}`):**
   - `torch-dev` automatically prioritizes a project-local `./.venv` if present, otherwise auto-activates `~/.local/share/rocm/venv-${gfx}`.
   - On first run, `torch-dev` automatically bootstraps the shared environment once. All subsequent launches in any folder activate instantly (0.01s).
   - `init-rocm-venv` supports `--flash-attn` (and `--with-flash-attn`) to automatically compile and install Flash Attention 2 during environment bootstrap.
   - Live hardware validated on Radeon 8060S (`gfx1151`) with standard and packed QKV forward passes (`flash_attn_func`, `flash_attn_qkvpacked_func`).
   - Exported `flake.lib.mkRocmDevShells` to allow instantiating shells for any GPU architecture.
4. **Host Leaf Composition (`hosts/lunar-qualia/default.nix`):**
   - Configured `suites.ai.rocm.enable = true; suites.ai.rocm.gfx = "gfx1151";`.
   - Verified dry-run evaluation and built generation locally via `nh os build`.
5. **Populated Precomputed SRI Hashes for All Architectures (`pkgs/rocm-therock/default.nix`):**
   - Sourced and verified official SHA-256 SRI hashes directly from AMD's stable distribution tarballs.
   - Fully covered AMD APUs (`gfx1150`, `gfx1151`, `gfx1152`, `gfx1153`), RDNA 3 (`gfx1100`–`gfx1103`, `gfx110X-all`), RDNA 2 (`gfx1030`–`gfx1035`, `gfx103X-all`), RDNA 1 (`gfx1010`–`gfx1012`, `gfx101X-dgpu`), RDNA 4 (`gfx1200`–`gfx1201`, `gfx120X-all`), CDNA (`gfx908`, `gfx90a`, `gfx942`, `gfx94X-dcgpu`, `gfx950`, `gfx125X-dcgpu`), and universal `multiarch`.
   - Zero configuration required for users targeting any of these architectures without needing to pass an explicit `hash`.
6. **Added Universal Archive Utilities (`modules/core/default.nix`):**
   - Declared `zip` and companion `unzip` in baseline `environment.systemPackages`.
7. **Decommissioned Legacy `rocmctl` Tooling:**
   - Deleted the obsolete Fedora-era binary `/home/nnon/.local/bin/rocmctl` and purged the legacy skill directory at `~/.gemini/config/skills/rocmctl`.
8. **Refactored `suite-ai-rocm` to 3-Tier Best Practice (`modules/suites/ai/rocm.nix`):**
   - Replaced full compiler package on global `$PATH` with lightweight `rocm-diagnostics` wrapper exposing only `rocminfo`, `amd-smi`, and `rocm_agent_enumerator`.
   - Stripped global `ROCM_PATH`, `HIP_PATH`, and `CMAKE_PREFIX_PATH` session variables to eliminate pollution of unrelated CMake/host builds.
   - Retained dynamic library resolution in `programs.nix-ld.libraries` for standalone binaries.
   - Kept full compiler suite, include paths, and Python AI venv automation strictly within `devShells` (`amd-ai-dev`).
   - Removed `exposeCompilers` toggle entirely to enforce strict isolation of compilers to devshells.
9. **Decoupled Flake DevShells to `shells/` Aggregator (`shells/rocm.nix`, `shells/loom.nix`, `flake.nix`):**
   - Created top-level `shells/default.nix` aggregator imported directly into `flake.nix`, maintaining clear domain boundaries.
10. **Integrated Build Caching (`shells/rocm.nix`):**
    - Packaged `ccache` and `sccache` into `amd-ai-dev` developer shell.
    - Configured `CMAKE_C_COMPILER_LAUNCHER = "ccache"` and `CMAKE_CXX_COMPILER_LAUNCHER = "ccache"` for zero-configuration build acceleration.
11. **AMD XDNA & ROCm Loom Architecture Research (`retrospects/05-*`, `retrospects/06-*`):**
    - Proved in-tree `amdxdna` kernel driver is loaded and initialized on Linux 7.2.8 (`/dev/accel/accel0`, FW `1.1.2.65`, `NPU Strix Halo`, PCI `17f0:11`). No DKMS driver required.
    - Documented 5-layer XDNA stack and proved both C++ (`aie_api` + XRT Native C++ API) and Python (`aie.iron` DSL + `pyxrt`) workflows.
    - Investigated `mlir-aie` latest updates and official AMD Agent Skills (`aie-model-baseline`, `aie-dataflow-presim`, `aie-hw-bringup`, `aie-kernel-opt`, `aie-dataflow-opt`).
    - Discovered ROCm Loom (`ROCm/hrx-system`) compiler targeting both AMDGPU (`gfx1151`) and AMD XDNA (`strix_halo.17f0_11`).
    - Documented how Loom executes `.xdna` ELFs via `libamdf` over native Linux DRM, completely bypassing XRT on Linux.
12. **Fixed `libhipblaslt` & Math Libraries ELF Header Corruption (`pkgs/rocm-therock/default.nix`):**
    - Root-cause: `autoPatchelfHook` forcibly moved tail `PT_PHDR` segments to offset 0x40 and underflowed `VirtAddr` to negative values (`0xffffffffffd9d040`), crashing dynamic linker `_dl_map_new_object` with SIGSEGV in `llama-cli` and `rocblas`.
    - Fix: Removed `autoPatchelfHook`. Kept 100% of `.so` files pristine and unpatched (they already use `$ORIGIN/rocm_sysdeps/lib` relative rpaths). Selectively patched only executable binaries in `bin/` and `lib/llvm/bin/` with interpreter and RPATH.
    - Verified `libhipblaslt.so.1` and `librocblas.so.5` load with 0 errors via Python `ctypes.CDLL`.
13. **Two-Shell Architecture Implementation (`shells/rocm.nix`, `shells/loom.nix`, `shells/default.nix`):**
    - `amd-ai-dev` (default `nix develop`): Unified flagship devshell combining ROCm TheRock, Rust toolchain (`cargo`, `rustc`), build tools (`cmake`, `ninja`, `ccache`, `sccache`), PyTorch 2.12 + Flash Attention 2, and XDNA IRON helpers. Backward-compatible aliases for `torch-dev` and `hip-dev`.
    - `loom-dev`: ROCm Loom & HRX System studio with Bazelisk, Bazel 7, CMake, LLVM/Clang, Python, and hardware target configuration for both Radeon 8060S (`gfx1151`) and Ryzen AI NPU (`amd.xdna.aie2p:amd.xdna.strix_halo.17f0_11`).
14. **AMD XDNA (IRON & XRT) Live Hardware Verification (`retrospects/07-*`):**
    - Proven on live hardware (`lunar-qualia`, Strix Halo AIE2p NPU `0000:65:00.1` on Linux 7.2.8 with FW `1.1.2.65`).
    - Successfully verified `xrt-smi examine` hardware detection and telemetry.
    - Verified `pyxrt` physical DMA buffer allocation (`pyxrt.bo`), cacheable memory transfers, and bit-exact readback.
    - Resolved `robcohen/nix-amd-npu` version mismatch by pairing XRT `2.21.75` with `amdxdna-driver-2.21.75`.
    - Identified and bypassed `RLIMIT_MEMLOCK` EAGAIN requirement for the 64 MB kernel ring buffer.
    - Successfully JIT-compiled Python `@iron.jit` designs to MLIR targeting `aie.device(npu2)` using Peano Clang 21 and `aiecc`.
    - Executed multi-tile streaming vector compute kernel on physical NPU tiles via double-buffered `ObjectFifo` DMAs with 100% bit-exact correctness across 4096 elements.
15. **In-Tree XRT & AMDXDNA Driver Nix Derivation (`pkgs/xrt-amdxdna`, `pkgs/default.nix`):**
    - Sourced official, matched Arch Linux binaries for XRT `2.21.75` + AMDXDNA driver plugin `2.21.75` + Boost `1.92.0`.
    - Patched with `autoPatchelfHook` and `makeBinaryWrapper`, exporting `XILINX_XRT` and pre-configuring Python 3.14 auto-init.
    - Verified all shared objects (`libxrt_core`, `libxrt_coreutil`, `libxrt_driver_xdna`) resolve to Nix store dependencies without missing symbols.
16. **System-Wide Unlimited Locked Memory (`modules/core/default.nix`):**
    - Configured PAM login limits (`item = "memlock"; value = "unlimited"`) and modern NixOS 26.11 systemd parameters (`systemd.settings.Manager.DefaultLimitMEMLOCK = "infinity"`, `systemd.user.settings.Manager.DefaultLimitMEMLOCK = "infinity"`).
    - Eliminates the `mmap(flags=MAP_LOCKED) err=-11 EAGAIN` limit for the 64 MB hardware NPU DMA ring buffer.
17. **Integrated XDNA & Python 3.14 into Unified `amd-ai-dev` Shell (`shells/rocm.nix`, `shells/loom.nix`):**
    - Sourced `xrtPkg = pkgs.callPackage ../pkgs/xrt-amdxdna { }` directly into `amd-ai-dev`.
    - Switched devshell Python from hardcoded `python312` to NixOS 26.11 baseline Python 3.14 (`pkgs.python3`), matching the prebuilt `pyxrt` extension and official AMD PyTorch wheels (`torch==2.12.0+rocm10.1.0`).
    - Enhanced `init-rocm-venv` to link host `pyxrt` into `$VENV_DIR` via `xrt.pth` and auto-configure Peano compiler paths (`PEANO_INSTALL_DIR`, `AIECC_PATH`, `AIE_XCLBINUTIL`).
    - Verified `amd-ai-dev`, `loom-dev`, and `default` devshells evaluate and load cleanly.
18. **Dual-LLVM Collision Nuance & Multi-Device Runtime Proof:**
    - Proved that PyTorch ROCm (GPU) and `pyxrt` (NPU) run concurrently in the **same Python process** with zero errors (`torch.cuda.is_available() == True`, GPU sum computed, and NPU DMA buffer allocated simultaneously).
    - Identified that `import aie.iron` / `import mlir_aie` cannot be imported in the exact same process as `import torch` due to conflicting LLVM `cl::opt` CommandLine registrations (`print-inst-addrs`).
    - Confirmed standard decoupled workflow: compile kernels via IRON/MLIR AOT or in a compilation subshell, then dispatch compiled `.xclbin` binaries to the NPU via `pyxrt` in the PyTorch application.

---

## 3. In-Flight Tasks & Next Immediate Steps

- [x] Sourced and packaged in-tree `xrt-amdxdna` derivation.
- [x] Configured unlimited `memlock` in `modules/core/default.nix`.
- [x] Wired `xrt-amdxdna` and Python 3.14 into `shells/rocm.nix` (`amd-ai-dev`).
- [x] Tested evaluation and devshell launches (`amd-ai-dev`, `loom-dev`, `default`).
- [ ] *(Optional / Next)*: Commit changes to Git and switch live system via `nh os switch`.

---

## 4. Architectural Notes & Gotchas for the Incoming Agent

1. **Privilege Escalation:**
   Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching. The system uses KDE Plasma's `ksshaskpass` graphical dialog.
2. **`gfx` Strict Invariant:**
   `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture. If invoked without an explicit architecture string, it throws an error / fails assertion by design.
3. **Python & Wheel Resolution:**
   The official TheRock aggregate wheel index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch wheels in TheRock are split: `torch` is architecture-neutral host code, while `amd-torch-device-${gfx}` carries the GPU kernel packs. In `torch-dev`, `PIP_CONSTRAINT` / `UV_CONSTRAINT` prevents third-party packages from replacing ROCm packages with PyPI CPU wheels.
