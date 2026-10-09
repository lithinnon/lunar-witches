# Incident Post-Mortem: AMDXDNA Driver Ring Buffer Allocation Failure (`err=-11 EAGAIN`)

> **Date:** 2026-10-09  
> **Status:** Resolved  
> **Component:** Linux Kernel driver `amdxdna` / XRT SHIM `libxrt_driver_xdna.so`  
> **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, XDNA 2 AIE2p NPU)  

---

## 1. Incident Summary

During the initial deployment of the native AMD XDNA stack (XRT 2.21.75 and pyxrt) on `lunar-qualia`, hardware discovery through `xrt-smi` and sysfs succeeded, recognizing the NPU at `0000:65:00.1` and `/dev/accel/accel0`.

However, any user-space process attempting to initialize an NPU execution context or allocate a hardware buffer object (`xrt.bo`) threw an unhandled runtime error:

```python
xrt.xrt_error: std::exception
```

Inspecting kernel ring buffers (`dmesg`) revealed repeated driver allocation rejections:

```text
[ 3959.043516] amdxdna 0000:65:00.1: [drm] amdxdna_cmd_alloc_ringbuf: alloc ringbuf failed, err -11
[ 3959.043519] amdxdna 0000:65:00.1: [drm] amdxdna_drm_create_hwctx: create hwctx failed, -11
```

---

## 2. Root Cause Analysis (RCA)

### Driver Architecture
The in-tree `amdxdna` accelerator driver implements hardware context creation via `DRM_IOCTL_AMDXDNA_CREATE_HWCTX`. During context creation:
1. The driver allocates a shared asynchronous command and response ring buffer between the host CPU and the NPU management firmware.
2. To ensure zero-copy DMA transfer and prevent hardware bus lockups, this ring buffer is allocated using kernel locked pages:
   ```c
   /* kernel/drivers/accel/amdxdna/amdxdna_ctx.c */
   mmap(..., MAP_LOCKED | MAP_SHARED, ...);
   ```
3. The default ring buffer sizing requires **64 MiB (67,108,864 bytes)** of contiguously pinned, locked physical memory per client process.

### The System Constraint
On default Linux and NixOS installations:
- Unprivileged user processes are subject to PAM and POSIX `RLIMIT_MEMLOCK` (`ulimit -l`).
- The default limit for standard user sessions is **8 MiB (8,388,608 bytes)** or **64 KiB**.
- When `amdxdna` called the locked memory allocator on behalf of user UID 1000 (`nnon`), the kernel evaluated the requested 64 MiB against the 8 MiB `RLIMIT_MEMLOCK` ceiling.
- The kernel rejected the allocation with POSIX error code `-11` (`-EAGAIN`: *Resource temporarily unavailable*).
- When executed as `root` (UID 0), `ulimit -l` was `unlimited`, allowing the context allocation to succeed immediately.

---

## 3. Remediation & Declarative Fix

### Declarative NixOS Configuration
To resolve this permanently across all login mechanisms (graphical Wayland sessions, SSH, subshells, and systemd user services), `modules/core/default.nix` was updated with:

1. **PAM Login Limits:**
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

*(Note: In modern NixOS 26.11 / systemd v261+, `systemd.extraConfig` is deprecated and removed. Setting `systemd.settings.Manager.DefaultLimitMEMLOCK` is the canonical mechanism).*

---

## 4. Verification

After applying Generation 103:
1. `systemctl show --property=DefaultLimitMEMLOCK` reports `infinity`.
2. `systemctl --user show --property=DefaultLimitMEMLOCK` reports `infinity`.
3. PAM configuration passes `conf=/nix/store/...-limits.conf` containing `* - memlock unlimited`.
4. User-space initialization and buffer allocation via `pyxrt` now execute without `EAGAIN` or root elevation requirements.
