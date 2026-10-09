# ADR 0016: Unlimited Locked Memory (`memlock`) for Hardware Accelerators

> **Status:** Accepted  
> **Date:** 2026-10-09  
> **Scope:** Kernel Limits, Memory Management & Accelerator DMA  

---

## 1. Context & Problem

Hardware accelerators operating over direct Linux kernel drivers (specifically the AMD XDNA NPU driver `amdxdna`, low-latency audio via PipeWire/ALSA, and high-performance ROCm/io_uring queues) allocate zero-copy command and response ring buffers.

These ring buffers must be pinned to contiguous physical memory pages via `mmap(..., MAP_LOCKED)`. The `amdxdna` kernel driver requires a contiguous **64 MiB (67,108,864 bytes)** pinned ring buffer per client process.

Under default Linux and NixOS configurations, unprivileged user processes are capped at 8 MiB (or 64 KiB) of locked memory (`RLIMIT_MEMLOCK` / `ulimit -l`), causing kernel hardware context creation to fail with:
```text
amdxdna 0000:65:00.1: [drm] amdxdna_cmd_alloc_ringbuf: alloc ringbuf failed, err -11
```

## 2. Decision

We configured unlimited locked memory limits globally across all session types in `modules/core/default.nix`:

1. **PAM Session Limits:**
   ```nix
   security.pam.loginLimits = [
     {
       domain = "*";
       item = "memlock";
       type = "-";
       value = "unlimited";
     }
   ];
   ```
2. **System & User Systemd Manager Limits:**
   ```nix
   systemd.settings.Manager.DefaultLimitMEMLOCK = "infinity";
   systemd.user.settings.Manager.DefaultLimitMEMLOCK = "infinity";
   ```

*(Note: Modern NixOS 26.11 / systemd 261+ deprecated and removed `systemd.extraConfig`; configuring `systemd.settings.Manager.DefaultLimitMEMLOCK` is the canonical declarative mechanism).*

## 3. Consequences

- User processes can initialize AMD XDNA NPU hardware contexts, allocate DMA buffer objects, and run vector kernels without root privileges.
- Prevents audio dropouts and queue stalls in PipeWire and io_uring.
