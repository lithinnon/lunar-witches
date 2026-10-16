# ADR 0002: CachyOS BORE Zen 4 Kernel & BTRFS Storage Layout

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Hardware, Kernel & Storage  
> **Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Strix Halo APU)  

---

## 1. Context & Problem

The primary target device (`lunar-qualia`) features high-density Zen 5 CPU cores (16 cores / 32 threads) and unified LPDDR5X-8000 memory. Standard upstream Linux kernels lack targeted microarchitecture scheduling optimizations, burst latency compensation, and NTSync synchronization primitives essential for high-responsiveness desktop and gaming workloads.

## 2. Decision

1. **Kernel Selection & Packaging (`chaotic-cx/nyx`):**
   - Adopted the CachyOS Zen 4 kernel with Clang ThinLTO (`-march=znver4`, AVX-512, BMI2, Full Preemption at 1000Hz).
   - Sourced via pre-compiled binary cache from Chaotic-Nyx (`chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"`, package `pkgs.linuxPackages_cachyos-lto-znver4`, cache `https://nyx-cache.chaotic.cx`).
   - *(Note: Migrated on 2026-10-16 from the decommissioned `xddxdd/nix-cachyos-kernel` repository following the maintainer's infrastructure breach and server shutdown; selected `linuxPackages_cachyos-lto-znver4` for hardware silicon instruction set alignment on Strix Halo)*.
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
