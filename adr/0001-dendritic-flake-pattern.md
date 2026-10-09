# ADR 0001: Dendritic Flake Structure Powered by Flake-Parts

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Repository Architecture  

---

## 1. Context & Problem

A traditional monolithic `configuration.nix` rapidly accumulates tangled dependencies between machine hardware quirks (e.g. ASUS laptop ACPI, AMD GPU parameters), desktop environments, developer toolchains, and user profiles. As configurations grow or expand to multiple machines, monolithic structures lead to copy-paste drift and brittle evaluations.

## 2. Decision

We adopted a **dendritic module pattern** powered by `flake-parts`:
1. **Modularity (`modules/`):** Hardware quirks, desktop configurations, core foundation, and services are decoupled into self-contained NixOS modules exported via `flake.nixosModules.*`.
2. **Host Specialization (`hosts/`):** The `hosts/` directory contains per-machine leaf declarations (`hosts/<hostname>/default.nix`) that compose traits and supply machine-specific physical parameters (partitions, UUIDs, RAM limits).
3. **Integrated Home Manager:** Home Manager is imported directly as a NixOS module (`inputs.home-manager.nixosModules.home-manager`) using `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true`. This aligns system packages and user packages under a unified `nixpkgs` evaluation pass.

## 3. Consequences

- Modules can be mixed and matched across different form factors (laptops, stationary desktops, servers).
- Evaluations are fully hermetic and cacheable.
- Host manifests remain declarative leaf aggregators without repeating plumbing logic.
