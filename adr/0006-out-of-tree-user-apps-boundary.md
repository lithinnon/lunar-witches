# ADR 0006: Repository Scope & Boundaries: Out-of-Tree User Applications (BullVPN Boundary)

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Repository Scope & Architecture Boundaries  

---

## 1. Context & Problem

There is an impulse to package every application installed on a system inside the system configuration flake (`pkgs/`). However, applications that are actively developed, frequently tagged, or undergo rapid server/API churn (such as BullVPN) create continuous commit noise, merge conflicts, and lockfile rebuild churn in the operating system repository.

## 2. Decision

1. **Clear Packaging Criteria for `pkgs/`:**
   - Packages in `pkgs/` are strictly reserved for:
     - System-wide hardware daemons (`amdgpu-boost`).
     - Kernel/hardware monitoring utilities (`mem-ttm`).
     - Desktop integration helpers (`sync-power-state`, `service-deck-helper`).
     - Machine drivers and hardware acceleration runtimes (`xrt-amdxdna`, `rocm-therock`).
2. **Out-of-Tree Boundary (e.g. BullVPN):**
   - Rapidly evolving consumer/network applications remain in their own independent repositories under user space (`~/sources/`).
   - Sourced and managed via standard user tooling rather than bloating the OS flake lifecycle.

## 3. Consequences

- The OS flake git history remains focused on infrastructure, hardware traits, and declarative system state.
- Frequent application release cycles do not trigger NixOS rebuilds or flake lock bumps.
