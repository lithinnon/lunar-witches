# ADR 05: AMD XDNA NPU Architecture, Programming Model & System Readiness

> **Status:** Research / RFC  
> **Date:** 2026-10-09  
> **Target Hardware:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Strix Halo APU, 32GB LPDDR5X)  
> **NPU Architecture:** XDNA 2 / AIE2p (`aie2p`, 6×8 compute tile array topology, 50 TOPS INT8 / BF16)  

---

## 1. Context & Motivation

AMD Ryzen AI processors incorporate an integrated Neural Processing Unit (NPU) based on Xilinx AI Engine (AIE) architecture. On the Strix Halo APU (`lunar-qualia`), the NPU is an **AIE2p** design featuring 512-bit vector processing units, streaming DMAs, tile-local data memories, and a programmable AXI interconnect.

The objective of this research is to establish how to properly enable AMD XDNA development on NixOS for both **Python** (via MLIR-AIE and the IRON DSL) and **C++** (via `aie_api` vector kernels and the Native XRT C++ host runtime), without relying on container tooling (Docker/Podman) or imperative package managers.

---

## 2. Hardware & Kernel Status Verification

Inspection of the live system on `lunar-qualia` confirms the lower kernel-hardware stack is fully functional out of the box on Linux 7.2.8-cachyos:

```bash
$ ls -la /dev/accel/accel0
crw-rw-rw- 1 root render 261, 0 Oct  7 17:10 /dev/accel/accel0

$ cat /sys/class/accel/accel0/device/vbnv
NPU Strix Halo

$ cat /sys/class/accel/accel0/device/fw_version
1.1.2.65
```

- **Kernel Driver:** In-tree `amdxdna` kernel driver is loaded and actively bound to the PCI accelerator device.
- **Hardware Identification:** Identified as `NPU Strix Halo`, running firmware `1.1.2.65`.
- **Permissions:** Device node belongs to group `render` (`crw-rw-rw-`), which user `nnon` is already a member of.
- **Key Finding:** **No out-of-tree DKMS driver is required.** The entire implementation effort is strictly in userspace libraries, compiler toolchains, and runtime dependencies.

---

## 3. The 5-Layer XDNA Software Stack

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Layer 5: Application Code                       │
│   • Python: IRON DSL (aie.iron, ObjectFifo, Worker, @iron.jit)         │
│   • C++:    aie_api Vector Kernels  +  Native XRT Host Controller      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                  Layer 4: Compiler Toolchains                          │
│   • MLIR-AIE: Dialects (aie, aiex), aie-opt, tile place & route, aiecc │
│   • Peano (llvm-aie): Clang fork targeting 'aie2p-none-elf'            │
│   • llvm-objcopy: AIE2 symbol renames & ELF packaging                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                  Layer 3: Userspace Runtime (XRT)                      │
│   • libxrt_core / libxrt_coreutil (DMA Buffer Objects, xclbin loader)  │
│   • xrt-plugin-amdxdna (SHIM translating XRT HAL calls to /dev/accel)  │
│   • pyxrt (Python C++ bindings for libxrt_coreutil)                    │
│   • xrt-smi CLI (discovery, telemetry, diagnostics)                    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                  Layer 2: Kernel Driver (ALREADY ACTIVE)               │
│   • in-tree amdxdna driver (/dev/accel/accel0) in Linux 7.2.8          │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                  Layer 1: Silicon (ALREADY PRESENT)                    │
│   • Ryzen AI Max+ 392 NPU (Strix Halo AIE2p, 6×8 tile array, 50 TOPS)  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Programming Model Breakdown

### 4.1. In C++

An XDNA C++ application consists of two decoupled components:

1. **AIE Core Vector Kernel (`kernel.cc`):**
   - Targets the AIE2p VLIW vector processors.
   - Uses AMD's header-only `aie_api/aie.hpp` vector intrinsics (512-bit vector units, 32× BF16 or 64× INT8 parallel lanes).
   - Compiled via **Peano Clang**:
     ```bash
     clang -target aie2p-none-elf -O2 -c kernel.cc -o kernel.o
     ```

2. **Host Application Controller (`host.cpp`):**
   - Targets the host x86_64 CPU.
   - Uses the Native XRT C++ API (`#include <xrt/xrt_device.h>`, `#include <xrt/xrt_bo.h>`, `#include <xrt/xrt_kernel.h>`).
   - Links against `libxrt_coreutil.so`.
   - Workflow:
     1. Open device (`xrt::device device(0)`).
     2. Register compiled bitstream (`xrt::xclbin xclbin("design.xclbin")`).
     3. Allocate pinned DMA Buffer Objects (`xrt::bo`).
     4. Sync data from host RAM to NPU tile DMAs (`bo_in.sync(XCL_BO_SYNC_BO_TO_DEVICE)`).
     5. Dispatch kernel execution and await completion (`run.wait()`).
     6. Sync result buffer back to host RAM (`bo_out.sync(XCL_BO_SYNC_BO_FROM_DEVICE)`).

### 4.2. In Python (IRON / MLIR-AIE)

AMD provides the **IRON** framework (`aie.iron`), built into `mlir-aie`:
- **`ObjectFifo`**: Double-buffered streaming FIFO abstraction connecting host memory to tile DMAs.
- **`Worker`**: Binds compute operations to specific tiles in the 6×8 array.
- **`Runtime`**: Manages host tensor filling (`rt.fill`) and draining (`rt.drain`).
- **`@iron.jit`**: Compiles the design on the fly (running MLIR lowering, tile placement, routing, and Peano Clang), loads the generated `xclbin` via `pyxrt`, and executes seamlessly on `/dev/accel/accel0`.

---

## 5. Required Userspace Packages & System Dependencies

| Component | Upstream Source | Role |
| :--- | :--- | :--- |
| **`xrt`** | `Xilinx/XRT` | Host runtime, BO management, `libxrt_coreutil.so`, `xrt-smi` |
| **`xrt-plugin-amdxdna`** | `amd/xdna-driver` (userspace plugin) | Hardware SHIM library connecting XRT HAL to `/dev/accel/accel0` ioctls |
| **`pyxrt`** | Included in `xrt` (`src/runtime_src/python`) | Python bindings to XRT |
| **`llvm-aie` (Peano)** | `Xilinx/llvm-aie` | Clang/LLVM fork targeting `aie2p-none-elf` |
| **`mlir-aie`** | `Xilinx/mlir-aie` | MLIR dialects (`aie`, `aiex`), `aiecc.py`, `aie.iron` Python package, and `aie_api` |
| **`llvm-objcopy`** | Standard LLVM | Symbol renames required by IRON for AIE2 targets |

### Critical System Invariant: PAM `memlock` Limits
Running `ulimit -l` on `lunar-qualia` currently reports `8192` (8 MB).
XRT pins DMA Buffer Objects (`xrt::bo`) into physical memory. Buffers exceeding 8 MB (such as weight matrices or KV caches) will fail with `ENOMEM` or `EPERM` unless `memlock` is set to `unlimited` in NixOS:
```nix
security.pam.loginLimits = [
  { domain = "@render"; type = "-"; item = "memlock"; value = "unlimited"; }
];
```

---

## 6. Prospective NixOS Integration Options

1. **Flake Input (`nix-amd-npu` by robcohen):** Direct integration of community flake providing `xrt-amdxdna`, `llvm-aie`, `mlir-aie`, and ready devShells.
2. **In-Tree Dendritic Suite (`modules/suites/ai/xdna.nix`):** Declaratively exposing `xrt-smi` to system `$PATH`, libraries to `programs.nix-ld.libraries`, and devShells for C++ and Python.
3. **FHS DevShell with Prebuilt Wheels:** Fast path leveraging prebuilt `mlir_aie` and `llvm_aie` release wheels via `uv` within an FHS or `nix-ld` environment.
