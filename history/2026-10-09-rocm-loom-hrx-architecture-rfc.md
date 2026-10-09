# ADR 06: ROCm Loom (HRX System) Unified GPU + NPU Architecture

> **Status:** Research / RFC  
> **Date:** 2026-10-09  
> **Target Hardware:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Strix Halo APU, 32GB LPDDR5X)  
> **Primary Targets:** AMD Radeon 8060S (`gfx1151` RDNA 3.5 iGPU) & AMD Ryzen AI NPU (`amd.xdna.strix_halo.17f0_11` AIE2p)  
> **Upstream Repositories:** [`ROCm/hrx-system`](https://github.com/ROCm/hrx-system) | [Loom Programming Guide](https://rocm.github.io/hrx-system/loom/)  

---

## 1. Executive Summary

Historically, AMD's compute ecosystem was bifurcated across two disconnected runtime stacks:
- **GPU Computing:** ROCm (HIP, HSA, KFD, `amdgpu` driver, `.hsaco` code objects).
- **NPU Computing:** Xilinx legacy stack (XRT, XDNA driver plugin, `pyxrt`, MLIR-AIE, `.xclbin` bitstreams).

**ROCm Loom** (part of the **HRX System** — *HIP Runtime Extended*) is AMD's next-generation **source-first compiler and runtime system** designed specifically to bridge this divide. It provides a single, coherent compilation pipeline and execution model that targets **both AMD GPUs and AMD XDNA NPUs** natively.

---

## 2. The Paradigm Shift: Classic Separate Stacks vs. Loom (HRX)

```
================================================================================
                    CLASSIC PARADIGM: TWO SILOED ECOSYSTEMS
================================================================================

   [ GPU Application ]                             [ NPU Application ]
           │                                               │
   ROCm HIP Runtime (libamdhip64)                  Xilinx Runtime (libxrt_core)
           │                                               │
   HSA / KFD System Layer                          XRT Hardware SHIM (xrt-plugin-amdxdna)
           │                                               │
   amdgpu Linux Driver (/dev/kfd)                  amdxdna Linux Driver (/dev/accel/accel0)
           │                                               │
   Radeon 8060S iGPU (gfx1151)                     Ryzen AI NPU (AIE2p 17f0:11)

================================================================================
                    LOOM (HRX) PARADIGM: UNIFIED HETEROGENEOUS STACK
================================================================================

                         [ Unified Heterogeneous Application ]
                                         │
                         Canonical Loom IR (.loom) / C API (loomc)
                                         │
                    ┌────────────────────┴────────────────────┐
                    ▼                                         ▼
            [ Loom AMDGPU Backend ]                  [ Loom XDNA Backend ]
            Target: gfx1151                          Target: strix_halo.17f0_11
                    │                                         │
            Native HSACO (.hsaco)                    Native XDNA ELF (.xdna)
                    │                                         │
            libhrx (HIP Runtime Extended)            libamdf (Direct Linux DRM)
                    │                                         │
            /dev/dri (amdgpu)                        /dev/accel/accel0 (DRM)
                    │                                         │
            Radeon 8060S iGPU                        Ryzen AI NPU
```

---

## 3. Detailed Architecture of ROCm Loom & HRX

### 3.1. What is HRX (*HIP Runtime Extended*)?
- Built by the ROCm compiler team and IREE developers.
- A lightweight, modular runtime replacing monolithic ROCm runtime layers.
- Supports runtime targets:
  - `IREE_HAL_DRIVER_AMDGPU=ON` (targeting `gfx942`, `gfx1151`, `gfx1201`).
  - Native Linux DRM transport for accelerators.

### 3.2. What is Loom?
- A **source-first compiler** for compute kernels and asynchronous device pipelines.
- Source format: Canonical `.loom` text and `.loombc` bytecode.
- Key properties:
  - **In-source verification:** Correctness cases (`check.case`) and benchmark workloads (`check.benchmark`) are written directly beside kernel code.
  - **Target-aware specialization:** Understands physical device constraints before committing to instruction lowers.
  - **Clean C ABI (`loomc`):** Can be embedded directly into custom runtimes, JIT compilers, or Python packages.

### 3.3. How Loom Targets the Strix Halo NPU (`strix_halo.17f0_11`)
Under `loom/docs/src/targets/xdna-pipelines.md` and `experimental/xdna/`:
- **Target Flag:**
  ```shell
  loom-compile gated-projection.loom \
    --root=@ffn_gate_up_quadratic_bf16 \
    --target=amd.xdna.aie2p:amd.xdna.strix_halo.17f0_11 \
    --config=ffn_gate_up.input_size=512 \
    --format=xdna \
    --output=projection.xdna
  ```
- **Silicon Match:** `strix_halo.17f0_11` corresponds exactly to the hardware PCI device IDs found on `lunar-qualia`:
  - Vendor: `0x1022`
  - Device: `0x17f0`
  - Revision: `0x11`
- **Output Artifact:** Standalone `.xdna` ELF containing:
  - Low configuration instructions targeting `amd.xdna.aie2p.configuration` (routes, DMAs, bindings).
  - VLIW tile machine code for active AIE2p cores.

### 3.4. The Runtime Breakthrough: Zero-XRT Execution via `libamdf`
Unlike MLIR-AIE (which relies on `libxrt_core`, `xrt-plugin-amdxdna`, and `pyxrt`), Loom execution on Linux:
- Uses the **`libamdf`** adapter (`experimental/xdna/iree-xdna-run`).
- Interfaces directly with the Linux DRM accelerator subsystem (`/dev/accel/accel0`).
- **Completely eliminates XRT, HSA, and ROCr runtime dependencies on Linux.**

---

## 4. Workload Strategy on Strix Halo (`lunar-qualia`)

With 32GB unified memory (up to 22.37 GB TTM allocation):

| Workload Category | Engine | Tooling Stack | Rationale |
| :--- | :--- | :--- | :--- |
| **Heavy Prefill & Diffusion** | Radeon 8060S (iGPU, 40 CUs) | ROCm TheRock (PyTorch 2.12, Triton, Flash Attention 2) | Maximizes high-bandwidth SIMT throughput; draws 30W–85W package power. |
| **Streaming Prototyping** | Ryzen AI NPU (AIE2p) | MLIR-AIE + IRON (Python DSL + XRT shim) | Best today for fast Python experimentation and official AMD Agent Skills. |
| **Unified Heterogeneous Pipelines** | iGPU + NPU | ROCm Loom (`hrx-system`) | Single compiler producing `.hsaco` + `.xdna` with zero runtime bloat. |

---

## 5. Summary Answer to Architectural Question

**Q: Are there ROCm + XRT, and Loom that is able to do both GPU and NPU?**

**A: Yes, exactly:**
1. **The Classic Duo (`ROCm` + `XRT`):** Two independent stacks that run in parallel. ROCm manages the GPU (`/dev/kfd`), while XRT manages the NPU (`/dev/accel/accel0`). Applications must maintain separate contexts, memory buffers, and compilers.
2. **The Modern Unifier (`Loom` / `hrx-system`):** AMD's new unified compiler system that understands both the RDNA 3.5 GPU and the AIE2p NPU. It produces `.hsaco` for the GPU and `.xdna` for the NPU, running over lightweight `libhrx` and `libamdf` without requiring XRT.
