# ADR 0010: Six-Tier Dendritic Decomposition & Parametric Hardware Traits

> **Status:** Accepted  
> **Date:** 2026-10-02  
> **Scope:** Architecture Hierarchy & Reusability  

---

## 1. Context & Problem

Monolithic hardware modules inevitably couple machine-specific constants (such as 32 GB RAM limits, specific DRM `card1` device paths, or monitor refresh rates) with generic hardware drivers (like AMD CPU microcode or AMDGPU drivers). This creates tight coupling and makes it impossible to reuse modules across stationary desktops, servers, or different laptop models.

## 2. Decision

We established a **6-Tier Dendritic Architecture**:

1. **Tier 1: Core Foundation (`modules/core/`):** Baseline Nix settings, `nh`, sudo askpass, locale, `nix-ld`. Zero GUI or hardware assumptions.
2. **Tier 2: Form Factor Roles (`modules/roles/`):** Machine physical forms: `laptop` (power profiles, lid switch, battery sync), `desktop` (stationary), `server` (headless), `boot-systemd`.
3. **Tier 3: Hardware Traits (`modules/hardware/`):** Silicon drivers decoupled by component: `cpu/amd`, `gpu/amd`, `gpu/amd-integrated`, `memory/zswap`, `network/realtek-rtw89`, `oem/asus/base`, `peripherals/yubikey`.
4. **Tier 4: Opt-In Features (`modules/features/`):** Background daemons and specific services: `amdgpu-boost`, `syncthing`, `chulawifi`, `openssh`.
5. **Tier 5: Software Suites (`modules/suites/`):** Curated package collections: `desktop/plasma`, `desktop/apps`, `gaming`, `ai`, `development`.
6. **Tier 6: Host Leaf Manifests (`hosts/<hostname>/default.nix`):** Composes the above tiers and supplies machine-specific parameters.

### Domain Rules:
- **Bottles vs. Steam:** `bottles` belongs in `suite-desktop-apps` because it runs productivity, VPN, and academic software. Dedicated game runners belong in `suite-gaming`.
- **Parametric Values:** Generic hardware modules never hardcode machine constants. Options like `hardware.amdgpu.integrated.ttmPagesLimit` are typed via `lib.mkOption` and assigned in the host leaf (`ttmPagesLimit = 5862940` for `lunar-qualia`'s 32GB RAM profile).

## 3. Consequences

- Any new machine (e.g. `lunar-station`) can be instantiated in minutes by composing existing traits without duplicating logic.
- Clear mental model and boundaries for agents and developers.
