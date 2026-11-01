# ADR 0011: Silicon Quirks, Client Automation & Upstream Alignment

> **Status:** Accepted  
> **Date:** 2026-10-02  
> **Scope:** Hardware Quirks, Kernel Parameters & Display Drivers  

---

## 1. Context & Problem

Linux configurations often accumulate obsolete kernel parameters, redundant driver environment variables, and misplaced subsystems across major kernel and Mesa releases.

## 2. Decision

1. **Upstream Mesa Alignment (Mesa 26.2.3):**
   - Mesa 26.1.0+ enables `bfloat16` by default on RDNA 3 and RDNA 3.5 architectures.
   - The obsolete environment variable `RADV_EXPERIMENTAL = "bfloat16"` was removed to prevent driver divergence.
2. **Kernel Parameter Hygiene:**
   - Removed aggressive `amdgpu.gpu_recovery=1` from baseline GPU traits.
3. **AMD Display Core IPS Sleep Quirk (`amdgpu.dcdebugmask=0x800`, superseded by [ADR 0018](./0018-s2idle-resume-hang-and-display-idle.md)):**
   - Modern AMD APUs (Strix Halo/Point) can hang during sleep/suspend transitions when entering Display Core Idle Power States (IPS 1/2) with internal eDP panels.
   - Parameterized as `hardware.amdgpu.integrated.disableDcIps = true;` and applied selectively to `lunar-qualia` without forcing it on external desktop cards.
4. **Computer Use Agent (CUA) Wayland Driver Boundary:**
   - Input automation tool `CUA_DRIVER_RS_ENABLE_WAYLAND = "1"` belongs in `suite-desktop-plasma`, not the AI compute suite.
   - Rationale: CUA interacts directly with the Wayland compositor, window management, and virtual seats, requiring an active display session.
5. **Native Module Wrapping Avoidance:**
   - Eliminated redundant option wrappers (e.g. `services.lunar-syncthing`) in favor of direct upstream options configured with `lib.mkDefault`.

## 3. Consequences

- Clean driver environment aligned with modern Mesa and Linux kernel standards.
- Sleep/suspend stability preserved on ASUS TUF A14 hardware.
