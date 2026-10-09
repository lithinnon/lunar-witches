# ADR 0002: CachyOS BORE Zen 4 Kernel & BTRFS Storage Layout

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Hardware, Kernel & Storage  
> **Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Strix Halo APU)  

---

## 1. Context & Problem

The primary target device (`lunar-qualia`) features high-density Zen 5 CPU cores (16 cores / 32 threads) and unified LPDDR5X-8000 memory. Standard upstream Linux kernels lack targeted microarchitecture scheduling optimizations, burst latency compensation, and NTSync synchronization primitives essential for high-responsiveness desktop and gaming workloads.

## 2. Decision

1. **Kernel Selection (`nix-cachyos-kernel`):**
   - Adopted the CachyOS BORE Zen 4 kernel (`Linux 7.2.8-cachyos`) with Zen 4/5 instruction tuning and the BORE (Burst-Oriented Response Enhancer) CPU scheduler.
   - Sourced directly via binary cache from the `nix-cachyos-kernel` flake input.
   - Leverages native `/dev/ntsync` for low-overhead Wine synchronization.
2. **BTRFS Subvolume Layout:**
   - Partitioned target NVMe with compression: `@`, `@home`, `@nix`, `@snapshots`, and `@log` use `compress=zstd:1` and `noatime` for optimal NVMe lifespan and read throughput.
   - `@swap` subvolume formatted with `nodatacow`, hosting a dedicated 48 GiB swapfile for hibernation capacity.
3. **ASUS Laptop Daemon & DPM Controls:**
   - Deployed `asusd` and `supergfxctl` for native fan curves, keyboard backlights, and power profiles.
   - Declared systemd tmpfiles rules for sysfs permissions governing thermal throttling and GPU boost governors.

## 3. Consequences

- Near-zero latency desktop UI interactivity even under heavy parallel compile loads.
- Native kernel synchronization available for Wine/Proton games via `/dev/ntsync`.
- Declarative power control without proprietary vendor background daemons.
