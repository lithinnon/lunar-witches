# ADR 0004: In-Tree Custom Derivations & Flake Overlay Pattern (`pkgs/`)

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Package Management & Custom Tooling  

---

## 1. Context & Problem

Host-specific helper scripts, DPM governors, and hardware monitors often live imperatively in `~/.local/bin`. Imperative scripts suffer from missing runtime dependencies, broken shebangs across system updates, and untracked drift between machines.

## 2. Decision

All custom tooling and hardware daemons are packaged as declarative Nix derivations under `pkgs/`:
- **`mem-ttm`:** Standalone Python derivation monitoring kernel sysfs TTM allocations with deterministic shebang patching.
- **`amdgpu-boost`:** Dual-threshold DPM governor & auto-display daemon wrapped via `makeWrapper` with all runtime dependencies (`systemd`, `dbus`, `libnotify`, `asusctl`, `kdePackages.libkscreen`, `gawk`, `gnused`).
- **`sync-power-state`:** AC vs. battery display refresh and platform state switcher wrapped with `kdePackages.libkscreen`.
- **`app` / `service-deck-helper`:** Custom utilities packaged with explicit dependencies.
- **`xrt-amdxdna`:** Packaged matched XRT 2.21.75 runtime, Boost 1.92, AMDXDNA plugin, and `pyxrt` for Python 3.14.

**Export Pattern:**
Packaged in `pkgs/default.nix` exposing `perSystem.packages` and exported via `flake.overlays.default`. Leaf hosts inject `nixpkgs.overlays = [ self.overlays.default ];`.

Systemd services directly invoke the immutable store binaries (e.g. `${pkgs.amdgpu-boost}/bin/amdgpu-boost --daemon`) rather than mutable user paths.

## 3. Consequences

- Zero runtime breakage from missing subcommands or broken shebangs.
- Services run against immutable, hermetically built binaries.
