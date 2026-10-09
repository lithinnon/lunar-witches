# ADR 0005: Anime Game Launcher (AAGL) & Binary Cache Strategy

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Gaming Suite & Wine Performance  

---

## 1. Context & Problem

Upstream Nixpkgs cannot package Hoyoverse and anime game launchers due to heavily patched Wine runners (`wine-dwproton-wow64`, `dxvk`), proprietary anticheat requirements, and licensing constraints. Compiling these runners from source on a user's machine consumes hours of CPU time.

## 2. Decision

1. **AAGL Flake Module Integration:**
   - Integrate `github:ezKEa/aagl-gtk-on-nix` directly into the gaming suite (`modules/suites/gaming/default.nix`).
   - Expose packages like `programs.honkers-launcher.enable = true;`.
2. **Binary Cache Substituter Optimization:**
   - Declare Cachix (`https://ezkea.cachix.org`) with its public signing key as a trusted substituter using `inputs.aagl.nixConfig`.
   - Ensures patched Wine and Proton binaries are substituted directly from cache rather than built locally.
3. **NTSync Integration:**
   - Leverage the CachyOS kernel's native `/dev/ntsync` module.
   - Replaces user-space wineserver synchronization bottlenecks with direct Linux kernel-level primitives.

## 3. Consequences

- Near-instant updates for gaming runners.
- Significantly reduced Wine CPU synchronization overhead in gaming workloads.
