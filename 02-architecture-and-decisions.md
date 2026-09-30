# Retrospect 02: Architecture & Technical Decisions

## 1. Dendritic Flake Structure
Instead of a monolithic `configuration.nix`, the repository adopts a **dendritic pattern** powered by `flake-parts`:
- **Modularity:** Hardware quirks, desktop configurations, and core services are segregated into reusable modules under `modules/`.
- **Host Specialization:** The `hosts/` directory contains per-machine definitions (`hosts/lunar-qualia`), separating device-specific hardware mounts from common logic.
- **Home Manager Integration:** Home Manager is imported as a NixOS module (`inputs.home-manager.nixosModules.home-manager`), using `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true`. This aligns system packages and user packages under the same nixpkgs evaluation pass.

---

## 2. Kernel & Hardware Optimization (Strix Halo gfx1151)
- **CachyOS BORE Zen 4 Kernel (`Linux 7.2.8-cachyos`):**
  - Rationale: High-performance Zen 4/5 instruction scheduling with BORE (Burst-Oriented Response Enhancer) for low-latency desktop interactive responsiveness.
  - Sourced directly from `nix-cachyos-kernel` cache.
- **BTRFS Filesystem Layout:**
  - `@`, `@home`, `@nix`, `@snapshots`, and `@log` use `compress=zstd:1` and `noatime` for optimal NVMe lifespan and read throughput.
  - `@swap` has `nodatacow` enabled, backed by a 48 GiB swapfile with high hibernation capacity.
- **ASUS ROG/TUF Integration:**
  - `asusd` and `supergfxctl` provide native hardware control over fan curves, keyboard backlights, and power profiles.
  - Sysfs permissions for thermal throttling policies and AMD GPU boost controls are declaratively managed via `systemd.tmpfiles.rules`.
- **Unified Memory & AMD TTM Allocations:**
  - AMD Strix Halo uses unified system RAM for VRAM.
  - The standalone script `~/.local/bin/amd-ttm` monitors the TTM page limit (5,994,012 pages ~ 22.87 GB VRAM ceiling).

---

## 3. Toolchains & Application Ecosystem
- **Native Applications over Flatpak:**
  - Flatpak is restricted solely to Waterfox (`net.waterfox.waterfox`).
  - Essential desktop applications (Brave, Digital, KeePassXC, Bottles, ProtonPlus, Telegram, LocalSend, Zoom, Equibop) are declared natively in `home.nix`.
- **Google Antigravity Suite:**
  - Built natively using `inputs.antigravity-nix`:
    - `google-antigravity`: Desktop orchestrator with full Wayland, Electron, and hardware acceleration support.
    - `google-antigravity-cli` (`agy`): Native CLI binary patched for NixOS.
- **Unpatched Dynamic Binary Compatibility (`nix-ld`):**
  - Configured in `modules/core/default.nix` with comprehensive shared libraries (glib, gtk3, mesa, systemd, alsa, NSS, etc.) allowing IDE language servers, prebuilt Node/Python wheels, and proprietary binaries to run out-of-the-box without manual patchelf.
- **Declarative Development Environment:**
  - `uv`: Modern ultra-fast Python package management.
  - `libnotify`: System notifications via `notify-send`.
  - `git`: Fully declarative user credentials, default branch, safe directory flags, and automated GPG commit signing.

---

## 4. In-Tree Custom Packages & Flake Overlay (`pkgs/`)
Custom scripts and hardware utilities are converted into declarative Nix derivations under `pkgs/`:
- **`amd-ttm`:** Standalone Python derivation monitoring kernel sysfs TTM allocations with deterministic shebang patching.
- **`amdgpu-boost`:** Dual-threshold DPM governor & auto-display daemon wrapped via `makeWrapper` with all runtime dependencies (`systemd`, `dbus`, `libnotify`, `asusctl`, `kdePackages.libkscreen`, `gawk`, `gnused`).
- **`sync-power-state`:** AC vs Battery display refresh and platform state switcher wrapped with `kdePackages.libkscreen`.
- **Export Pattern:** Defined in `pkgs/default.nix` exposing `perSystem.packages` and `flake.overlays.default`, injected via `nixpkgs.overlays`.
- **Daemon Integration:** Home Manager's `amdgpu-boost.service` directly invokes the immutable store binary `${pkgs.amdgpu-boost}/bin/amdgpu-boost --daemon` instead of relying on mutable `%h/.local/bin` paths.
