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
  - The custom package `pkgs.amd-ttm` monitors the TTM page limit (5,994,012 pages ~ 22.87 GB VRAM ceiling).

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

---

## 5. Anime Game Launcher (AAGL) & Binary Cache Strategy
- **Why AAGL (`ezKEa/aagl-gtk-on-nix`):**
  - Upstream NixOS nixpkgs cannot package Hoyoverse/anime game launchers due to custom Wine patches, anticheat handling, and licensing constraints.
  - The AAGL flake module integrates directly into NixOS (`inputs.aagl.nixosModules.default`), exposing packages like `programs.honkers-launcher.enable = true;`.
- **Binary Cache Optimization:**
  - Injecting `nix.settings = inputs.aagl.nixConfig;` ensures Cachix (`https://ezkea.cachix.org`) is recognized as a trusted substituter.
  - This avoids building patched Wine runners (`wine-dwproton-wow64`, `dxvk`) from source, saving hours of compilation time.
- **NTSync Integration:**
  - Paired with the CachyOS kernel's native `/dev/ntsync` module, AAGL launchers utilize fast kernel-level synchronization primitives rather than user-space wineserver polling.

---

## 6. Repository Scope & Boundaries: The BullVPN Separation
- **Package Selection Boundary:**
  - Not all utilities belong inside `pkgs/` in the system flake.
  - Utilities in `pkgs/` are intended for system-wide services (`amdgpu-boost`), hardware monitoring (`amd-ttm`), or desktop hooks (`sync-power-state`).
- **The BullVPN Case:**
  - BullVPN is an independently developed, actively versioned application with its own Git lifecycle, frequent upstream release tags, and server list changes.
  - Keeping it as an independent repository in `~/sources/` or user space avoids polluting the OS configuration flake with external commit logs or frequent lockfile bumps.

---

## 7. Multi-User Git Safety Boundary (`safe.directory`)
- **Background:**
  - Git CVE-2022-24765 introduced strict ownership verification: Git refuses to operate on a repository if the directory owner does not match the executing user UID.
- **NixOS Context:**
  - Flake builds, system switches (`sudo -A nh os switch`), or systemd activation scripts often execute as `root`, while the flake repository at `/home/nnon/lunar-witches` is owned by user `nnon` (UID 1000).
  - Without a declared exception, Git throws `fatal: detected dubious ownership in repository`.
- **Decision:**
  - Configured `programs.git.extraConfig.safe.directory = "*"` declaratively in `home.nix`.
  - Ensures seamless flake evaluations, git operations, and automated rebuilds across privilege boundaries without manual permissions workarounds.

---

## 8. Secrets Management & The World-Readable `/nix/store` Boundary
- **The Core Problem:**
  - On NixOS, any string declared in `.nix` files (e.g. `environment.sessionVariables` or `home.sessionVariables`) is serialized into plain-text derivations inside `/nix/store/`.
  - The Nix store is world-readable (`chmod -R a+r /nix/store`). Any unprivileged process or compromised script can inspect or grep keys out of the store.
  - Hardcoding secrets also risks committing them to Git history and leaking them when pushing flake repositories.
- **Strategy & Decision (Local Out-of-Tree Env File):**
  - Personal API tokens (e.g. `HF_TOKEN`, LLM keys) are kept outside the Nix store in `~/.config/secrets.env` with strict permissions (`chmod 600`).
  - Declaratively wired into shell startup in [`hosts/lunar-qualia/home.nix`](file:///home/nnon/lunar-witches/hosts/lunar-qualia/home.nix):
    - Fish: `test -f "$HOME/.config/secrets.env"; and source "$HOME/.config/secrets.env"` in `programs.fish.shellInit`.
    - Bash: `[ -f "$HOME/.config/secrets.env" ] && source "$HOME/.config/secrets.env"` in `programs.bash.initExtra`.
  - **Future Roadmap:** For system-level daemons or CI/CD deployments, adopt `sops-nix` or `agenix` to decrypt secrets into RAM (`/run/secrets/`).

---

## 9. Custom Protocol Handlers & Steam Artwork (`sgdboop`)
- **Integration:**
  - Packaged natively via `pkgs.sgdboop` in `home.packages`.
  - Automatically associates with the `x-scheme-handler/sgdb` MIME type (`com.steamgriddb.SGDBoop.desktop`).
  - Enables one-click custom game art injection (grids, banners, logos, icons) directly from the SteamGridDB web interface into Steam's local `userdata/<id>/config/grid/` directory without manual asset downloads.

---

## 10. Deep Dendritic Decomposition & Parametric Hardware Traits
- **Motivation:**
  - Monolithic hardware or desktop modules inevitably couple machine-specific numbers (such as a 32GB RAM limit or specific DRM card paths) and user preferences with generic hardware traits, breaking portability across laptops, stationary desktops, and servers.
- **Architectural Separation:**
  - **1. Universal Core (`modules/core/`):** Universal foundation (Nix flakes, `nh`, basic CLI utilities, locale, sudo) with zero GUI, gaming, or hardware assumptions.
  - **2. Form Factor Roles (`modules/roles/`):** `laptop` (power profiles, battery sync), `desktop` (stationary), and `server` (headless, no sleep targets).
  - **3. Hardware Traits (`modules/hardware/`):** Decomposed by silicon vendor (`cpu/amd`, `gpu/amd`, `gpu/amd-uma`), memory cache (`memory/zswap`), network chipsets (`network/realtek-rtw89`), OEM platforms (`oem/asus/base`, `oem/asus/laptop`), and peripherals (`yubikey`, `keychron`).
  - **4. Decoupled Features (`modules/features/`):** Opt-in daemons (`amdgpu-boost`, `syncthing`) defined with typed module options rather than forced on all AMD or desktop machines.
  - **5. Capability Suites (`modules/suites/`):** Segmented into `desktop/plasma`, `desktop/audio`, `desktop/fonts`, `desktop/apps`, `gaming`, `ai`, and `development`.
  - **6. Pure Composition Host Leaves (`hosts/<hostname>/default.nix`):** Composes the above traits and supplies the exact machine parameters.
- **Bottles Classification Rationale:**
  - `bottles` was deliberately placed in `suite-desktop-apps` rather than `suite-gaming` because it serves as a general-purpose Windows application container (used for productivity, utilities, creative software), unlike Steam or gaming-specific launchers.
- **Parametric UMA TTM Limits:**
  - `hardware.amdgpu.uma` exposes typed options (`ttmPagesLimit`, `overrideGfxVersion`, `rocmArch`) rather than hardcoding values.
  - On `lunar-qualia`, the leaf host configures `ttmPagesLimit = 5862940` (exactly 24,014,602,240 bytes / ~22.365 GiB for its 32GB RAM profile), allowing any future 64GB or 128GB Strix Halo machine to cleanly configure its own limit without modifying generic modules.
