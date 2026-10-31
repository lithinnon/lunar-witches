# Retrospect 09: Complete AMD AI Stack Architecture Manual (ROCm, PyTorch, XRT, IRON, HRX, Loom)

> **Date:** 2026-10-09  
> **Host:** `lunar-qualia` (ASUS TUF Gaming A14 FA401EA, AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB LPDDR5X-8000 UMA)  
> **Silicon Endpoints:**  
> - **GPU:** AMD Radeon 8060S (`0000:64:00.0`, `gfx1151`, RDNA 3.5, 40 CUs)  
> - **NPU:** AMD XDNA 2 AIE2p (`0000:65:00.1`, `amd.xdna.strix_halo.17f0_11`, `/dev/accel/accel0`, 50 TOPS)  
> **Repository:** `/home/nnon/lunar-witches` (NixOS 26.11 Zokor)  
> **Author:** Antigravity  

---

## 1. The Two Coexisting Worlds of AMD AI

AMD's AI software stack today exists in two paradigms: the **Production Classic Stack** and the **Next-Gen Unified Substrate**.

```
====================================================================================================
                        PARADIGM A: THE PRODUCTION CLASSIC STACK
====================================================================================================

      GPU Pipeline (SIMT)                                 NPU Pipeline (Spatial VLIW)
  ┌─────────────────────────────┐                     ┌──────────────────────────────────┐
  │ PyTorch 2.12 / FlashAttn 2  │                     │ MLIR-AIE / Python IRON DSL       │
  │ Triton / Composable Kernel  │                     │ Peano LLVM Clang 21              │
  └──────────────┬──────────────┘                     └────────────────┬─────────────────┘
                 ▼                                                     ▼
  ROCm 10.1 TheRock (amdclang++)                      xclbinutil (.xclbin generation)
                 ▼                                                     ▼
  libamdhip64 + HSA / KFD Runtime                     XRT Userspace (libxrt_core / pyxrt)
                 ▼                                                     ▼
  Linux amdgpu Driver (/dev/kfd)                      xrt-plugin-amdxdna Shim Driver
                 ▼                                                     ▼
  Radeon 8060S GPU (gfx1151)                          Linux amdxdna Driver (/dev/accel/accel0)
                                                                       ▼
                                                      Ryzen AI NPU (AIE2p 17f0:11)

====================================================================================================
                        PARADIGM B: THE NEXT-GEN UNIFIED SUBSTRATE
                                  (ROCm Loom & HRX System)
====================================================================================================

                               [ Unified Application / Inference Engine ]
                                                   │
                                     Canonical Loom IR (.loom)
                                                   │
                               ┌───────────────────┴───────────────────┐
                               ▼                                       ▼
                       [ Loom GPU Backend ]                    [ Loom XDNA Backend ]
                       Target: gfx1151                         Target: strix_halo.17f0_11
                               │                                       │
                       Native AMDGPU HSACO                     Native XDNA ELF (.xdna)
                               │                                       │
                       libhrx (HIP Runtime Extended)           libamdf (Direct Linux DRM)
                               │                                       │
                       /dev/dri (amdgpu)                       /dev/accel/accel0 (DRM)
                               │                                       │
                       Radeon 8060S GPU                        Ryzen AI NPU (Zero XRT)
```

---

## 2. Core Concepts: What Are HRX and Loom?

### What is HRX (*HIP Runtime Extended*)?
* **Definition:** HRX is AMD's experimental, ultra-lightweight **runtime engine and Hardware Abstraction Layer (HAL)** (~2 MiB library).
* **The Problem It Solves:** Standard ROCm userspace is monolithic and heavy (hundreds of MBs of HSA, KFD, ROCr, and legacy diagnostic daemons). This creates high per-dispatch latency and prevents clean coordination with non-GPU hardware like NPUs.
* **Key Features:**
  * **Unified Device Abstraction:** Contains HAL drivers for GPUs (`HAL/AMDGPU`), NPUs (`HAL/XDNA`), and CPUs under one coherent API.
  * **HIP API Compatibility Layer:** Ships an optional `libamdhip64.so` shim that intercepts standard HIP runtime calls (`hipMalloc`, `hipMemcpy`, `hipModuleLaunchKernel`).
  * **Low-Latency Inference:** Allows engines like `llama.cpp` (`-DGGML_HRX=ON`) to execute GPU kernels with up to **50%+ faster prompt prefill** by stripping away ROCm driver bloat.
  * **Direct Hardware Queues:** Uses modern command-buffer-based dispatch rather than legacy implicit streams.

### What is Loom?
* **Definition:** Loom is AMD's **source-first, native JIT and AOT compiler** for asynchronous device-oriented programs.
* **The Problem It Solves:** Historically, compiling for AMD GPUs required LLVM/Clang (`amdclang++`), while compiling for AMD NPUs required an entirely separate compiler stack (MLIR-AIE + Peano LLVM). There was no common compiler that understood both targets.
* **Key Features:**
  * **Single Multi-Target Compiler:** `loom-compile` understands both GPU targets (`amdgpu:gfx1151`) and NPU targets (`amd.xdna.aie2p:amd.xdna.strix_halo.17f0_11`).
  * **Source-First Verification:** Kernels, correctness tests (`check.case`), and benchmarks (`check.benchmark`) live in the same `.loom` file.
  * **Fast In-Memory JIT:** Can specialize and emit hardware machine code in 1–15 milliseconds at runtime via the `loomc` C ABI.
  * **Zero-XRT Emission:** Emits standalone `.xdna` ELFs executed directly by `libamdf` over Linux DRM, completely removing XRT from Linux.

---

## 3. The Concurrency & Collision Nuance: IRON vs. PyTorch

### Question: Can IRON run alongside PyTorch simultaneously?

**The exact technical reality:**

| Scenario | Works? | Why / Mechanism |
| :--- | :---: | :--- |
| **PyTorch ROCm (GPU) + `pyxrt` (NPU)** | **YES (Same Process)** | **Verified on Silicon.** PyTorch executes GPU kernels on `gfx1151`, while `pyxrt` allocates physical DMA buffers (`pyxrt.bo`) and dispatches NPU kernels on `17f0:11` within the **exact same Python process** without errors. `pyxrt` is pure C++ and does not link LLVM. |
| **PyTorch ROCm + `import aie.iron` / `mlir_aie`** | **NO (Same Process)** | **Dual-LLVM Collision.** PyTorch bundles AMD ROCm LLVM (`comgr`), while `mlir_aie` bundles Peano LLVM (`_aie.so`). Both register conflicting LLVM command-line flags (`cl::opt`), causing instant crash: `CommandLine Error: Option 'print-inst-addrs' registered more than once!`. |
| **Separate Process / Pipeline** | **YES** | Compile kernels to `.xclbin` via IRON in a build step or subprocess, then load and run them via `pyxrt` in your PyTorch application. |

---

## 4. Hardware Proof Ledger (Executed on `lunar-qualia`)

### Proof 1: ROCm TheRock + PyTorch + Flash Attention 2
* **Toolchain:** Sourced via in-tree [`pkgs/rocm-therock`](../../pkgs/rocm-therock).
* **Fix Applied:** Eliminated `autoPatchelfHook` on `.so` files to avoid integer underflow in `PT_PHDR` (`0xffffffffffd9d040`), fixing SIGSEGV in `libhipblaslt` and `llama-cli`.
* **Execution:** Bootstrapped Python 3.14 virtual environment with `torch==2.12.0+rocm10.1.0`, `amd-torch-device-gfx1151`, and compiled Flash Attention 2 with Composable Kernel backend.
* **Status:** Verified on physical Radeon 8060S with packed and standard QKV attention forward passes.

### Proof 2: AMD XDNA NPU via XRT & Python IRON
* **Toolchain:** Mainline Linux 7.2.8 `amdxdna` driver + in-tree [`pkgs/xrt-amdxdna`](../../pkgs/xrt-amdxdna) (XRT `2.21.75`).
* **Fix Applied:** Configured `memlock = unlimited` in `modules/core/default.nix` to satisfy the 64 MB hardware ring buffer requirement (`mmap MAP_LOCKED`).
* **Execution:** JIT-compiled 4-tile streaming vector kernel (`scale` multiplying 4096 integers) via `@iron.jit` using Peano Clang 21 and executed on physical NPU tiles.
* **Status:** Verified **0 mismatches (4096/4096 bit-exact match)** on physical AIE2p hardware.

### Proof 3: ROCm Loom on Physical NPU (Zero XRT)
* **Toolchain:** Built `hrx-system` with `AMDF_BUILD=ON` and `AMDF_FAMILY_XDNA=ON` in `loom-dev`.
* **Execution:** Compiled `add_i32.loom` to `/tmp/compiled_add.xdna` using `loom-compile --target=amd.xdna.aie2p:amd.xdna.strix_halo.17f0_11`.
* **Silicon Run:** Executed via `iree-xdna-run` over `libamdf` directly to `/dev/accel/accel0`.
* **Status:** Verified **100% bit-exact output** across 16 elements on physical AIE2p tiles with **zero XRT libraries loaded**.

### Proof 4: ROCm Loom on Physical GPU (Radeon 8060S)
* **Toolchain:** Built `emit_amdgpu_hsa` and `iree_hal_execution_test` in `loom-dev`.
* **Execution:** Discovered GPU agent `gfx1151`, JIT-compiled Loom source to native HSACO in memory, and launched kernel via raw HSA (`output=42`).
* **Status:** Ran `LoomcAmdgpuIreeHalExecutionTest` (including 64-bit addressing beyond 4 GiB) on physical silicon with **3/3 tests PASSED**.

---

## 5. Developer Shell Cheat Sheet

| DevShell | Command | Purpose & Best Use Cases |
| :--- | :--- | :--- |
| **`amd-ai-dev`** | `nix develop /home/nnon/lunar-witches#amd-ai-dev` | **Flagship AI Development:** PyTorch ROCm 2.12, Flash Attention 2, Triton, HuggingFace models, Rust toolchain (`cargo`/`rustc`), CMake, Ccache, and NPU execution via `pyxrt` + `xrt-smi`. |
| **`loom-dev`** | `nix develop /home/nnon/lunar-witches#loom-dev` | **Next-Gen Substrate Studio:** ROCm Loom, HRX System, `libamdf`, Bazel 7, CMake, Clang, direct-to-DRM NPU `.xdna` compilation, and `llama.cpp` HRX backend development. |
| **`default`** | `nix develop /home/nnon/lunar-witches` | **Flake Maintenance:** Lightweight shell providing `nixd` (language server) and `nixfmt`. |
