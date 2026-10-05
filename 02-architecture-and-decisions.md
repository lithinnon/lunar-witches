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
  - The custom package `pkgs.mem-ttm` monitors the TTM page limit (5,994,012 pages ~ 22.87 GB VRAM ceiling).

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
- **`mem-ttm`:** Standalone Python derivation monitoring kernel sysfs TTM allocations with deterministic shebang patching.
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
  - Utilities in `pkgs/` are intended for system-wide services (`amdgpu-boost`), hardware monitoring (`mem-ttm`), or desktop hooks (`sync-power-state`).
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
  - **3. Hardware Traits (`modules/hardware/`):** Decomposed by silicon vendor (`cpu/amd`, `gpu/amd`, `gpu/amd-integrated`), memory cache (`memory/zswap`), network chipsets (`network/realtek-rtw89`), OEM platforms (`oem/asus/base`, `oem/asus/laptop`), and peripherals (`yubikey`, `keychron`).
  - **4. Decoupled Features (`modules/features/`):** Opt-in daemons (`amdgpu-boost`, `syncthing`) defined with typed module options rather than forced on all AMD or desktop machines.
  - **5. Capability Suites (`modules/suites/`):** Segmented into `desktop/plasma`, `desktop/audio`, `desktop/fonts`, `desktop/apps`, `gaming`, `ai`, and `development`.
  - **6. Pure Composition Host Leaves (`hosts/<hostname>/default.nix`):** Composes the above traits and supplies the exact machine parameters.
- **Bottles Classification Rationale:**
  - `bottles` was deliberately placed in `suite-desktop-apps` rather than `suite-gaming` because it serves as a general-purpose Windows application container (used for productivity, utilities, creative software), unlike Steam or gaming-specific launchers.
- **Parametric Integrated GPU & TTM Limits:**
  - `hardware.amdgpu.integrated` exposes typed options (`ttmPagesLimit`, `overrideGfxVersion`, `rocmArch`, `disableDcIps`) rather than hardcoding values.
  - On `lunar-qualia`, the leaf host configures `ttmPagesLimit = 5862940` (exactly 24,014,602,240 bytes / ~22.365 GiB for its 32GB RAM profile), allowing any future 64GB or 128GB Strix Halo machine to cleanly configure its own limit without modifying generic modules.

---

## 11. Silicon Quirks, Client Automation & Upstream Alignment
- **Mesa Upstream Alignment (Mesa 26.2.3):**
  - Checked the current Mesa version in nixpkgs (`26.2.3`). Because Mesa 26.1.0+ enables `bfloat16` by default for RDNA 3 and RDNA 3.5 architectures, the legacy `RADV_EXPERIMENTAL = "bfloat16"` environment variable was safely eliminated.
- **Kernel Parameter Hygiene:**
  - Removed `amdgpu.gpu_recovery=1` from baseline GPU traits.
- **AMD Display Core IPS Sleep Quirk (`amdgpu.dcdebugmask=0x800`):**
  - Newer AMD APUs exhibit sleep/suspend hangs when entering Display Core Idle Power States (IPS 1/2) with internal eDP panels.
  - Rather than forcing this on all AMD machines, it was parameterized as `hardware.amdgpu.integrated.disableDcIps = true;` and enabled specifically on `lunar-qualia`.
- **Computer Use Agent (CUA) Wayland Driver Boundary:**
  - `CUA_DRIVER_RS_ENABLE_WAYLAND = "1"` was decoupled from the Antigravity AI compute suite and integrated into `suite-desktop-plasma`.
  - Rationale: Computer Use automation is a client-side capability that manipulates windows, cursor, and keyboard input, strictly requiring an active graphical desktop/window manager rather than an AI inference backend.
- **Native Syncthing Option Standardization:**
  - Removed the custom `services.lunar-syncthing` option wrapper in favor of native NixOS `services.syncthing` configured via `lib.mkDefault`, maintaining idiomatic NixOS option naming.

---

## 12. Enterprise 802.1x Authentication & Campus Wi-Fi (`ChulaWiFi`)
- **Problem & Root Causes:**
  - Modern Linux distributions running OpenSSL 3 enforce `SECLEVEL=2` by default, which rejects the legacy ciphers and TLS 1.0/1.1 handshakes used by Chulalongkorn University's RADIUS authentication servers, misreporting connection aborts as generic auth failures or missing secrets.
  - `wpa_supplicant` disables TLS 1.0 in phase 1 outer authentication by default on modern builds.
- **Architectural Solution (`feature-chulawifi`):**
  - Encapsulated into [`modules/features/chulawifi.nix`](file:///home/nnon/lunar-witches/modules/features/chulawifi.nix) exporting `self.nixosModules.feature-chulawifi`.
  - **Upstream Adoption (`chula-flake`):** Profile generation delegated entirely to the [`chula`](https://github.com/MiniHarinn/chula-flake) flake input (`chula.nixosModules.wifi`), which provides the ChulaWiFi/eduroam declarative profiles, a pinned RADIUS CA (`radius-ca.pem`), and native `ensureProfiles.environmentFiles`/`envsubst` credential substitution (identity via `$CHULA_WIFI_IDENTITY`, password via `$CHULA_WIFI_PASSWORD`). [`modules/features/chulawifi.nix`](file:///home/nnon/lunar-witches/modules/features/chulawifi.nix) is a bare import-time trait that only layers the single quirk upstream lacks: `phase1-auth-flags = 32`. Host leaves configure `chula.wifi.environmentFile` directly.
  - Configures `openssl-ciphers = "DEFAULT@SECLEVEL=0"` and `phase1-auth-flags = 32` (`0x20` = `tls-1-0-enable`) on the 802.1x PEAP-MSCHAPv2 profile.
  - **Secrets Boundary:** Uses NetworkManager's native `ensureProfiles` mechanism combined with `environmentFiles = [ "/home/nnon/.config/secrets.env" ]`. At boot/activation, `envsubst` generates the profile directly into `/run/NetworkManager/system-connections/ChulaWiFi.nmconnection` (RAM tmpfs with `0600` permissions), completely preserving the boundary that secrets never touch the world-readable `/nix/store`.
  - **Update (2026-10):** With the chula-flake adoption the credential env file moved to a dedicated `~/.config/chula/environment` (`chmod 600`, `CHULA_WIFI_IDENTITY` + `CHULA_WIFI_PASSWORD`), separating it from the shell-sourced `~/.config/secrets.env` (`HF_TOKEN`). Systemd's `EnvironmentFile=` silently ignores `export `-prefixed lines, so these files must use plain `KEY=VALUE` form. Profiles now land in `/run/NetworkManager/system-connections/*.nmconnection` (both `chula-wifi` and `chula-eduroam`), and identity is resolved at runtime from the env file rather than baked into the store.
- **Wi-Fi & Bluetooth Antenna Contention:**
  - The Realtek RTL8852CE combo card shares physical radio antennas between Wi-Fi and Bluetooth. 802.11 dynamic power save causes background probe scans that lock the Packet Traffic Arbitration (PTA) engine, starving Bluetooth audio streams.
  - Disabled Wi-Fi power save declaratively in [`modules/roles/laptop.nix`](file:///home/nnon/lunar-witches/modules/roles/laptop.nix) (`networking.networkmanager.wifi.powersave = false`) complementing the low-level kernel module parameter in [`hw-network-realtek-rtw89`](file:///home/nnon/lunar-witches/modules/hardware/network/realtek-rtw89.nix) (`options rtw89_core disable_ps_mode=y`).

---

## 13. Hardened OpenSSH Daemon & Passphrase-Backed SSH Agent Integration
- **Inbound SSH Server (`feature-openssh`):**
  - Encapsulated into [`modules/features/openssh.nix`](file:///home/nnon/lunar-witches/modules/features/openssh.nix) exporting `self.nixosModules.feature-openssh`.
  - Enforces strict key-only authentication: `PasswordAuthentication = false`, `KbdInteractiveAuthentication = false`, `PermitRootLogin = "no"`.
  - Authorized public keys are managed declaratively in [`modules/users/nnon.nix`](file:///home/nnon/lunar-witches/modules/users/nnon.nix) under `users.users.nnon.openssh.authorizedKeys.keys`.
- **Outbound SSH Client & Passphrase Management:**
  - `programs.ssh.startAgent = true;` provisioned in [`modules/core/default.nix`](file:///home/nnon/lunar-witches/modules/core/default.nix) to ensure a systemd user OpenSSH agent runs on all machines and exports `SSH_AUTH_SOCK` seamlessly across shells (fish/bash).
  - Configured graphical passphrase caching via KDE Plasma's `ksshaskpass` (`SSH_ASKPASS` and `SSH_ASKPASS_REQUIRE = "prefer"`) in [`modules/suites/desktop/plasma.nix`](file:///home/nnon/lunar-witches/modules/suites/desktop/plasma.nix) and user session variables, allowing KWallet to securely remember passphrases for encrypted Ed25519 keys.
  - SSH client aliases (`white`, `i2cedt-2`) and `addKeysToAgent = "yes"` declared purely in Home Manager's `programs.ssh`.

---

## 14. Declarative Home Manager Configuration & Custom In-Tree Script Packaging
- **Declarative User Applications (Tier 1):**
  - Migrated VS Code settings and extensions to `programs.vscode.profiles.default` in [`modules/users/nnon.nix`](file:///home/nnon/lunar-witches/modules/users/nnon.nix).
  - Integrated Fastfetch (`programs.fastfetch`) with custom Marie-Eve asset logo and modules.
  - Standardized XDG base directories via `xdg.userDirs` with `Projects` and `Templates`, while suppressing unused `publicShare`.
  - Declared default application handlers via `xdg.mimeApps.defaultApplications`.
  - Configured Btop system monitoring via `programs.btop.settings`.
- **Custom Desktop Platform Traits & Script Packaging (Tier 2):**
  - Adopted native Berkeley Espresso (`pkgs.espresso`) from nixpkgs for Digital PLA minimization, obviating Wine/Bottles emulation.
  - Packaged [`pkgs/service-deck-helper`](file:///home/nnon/lunar-witches/pkgs/service-deck-helper) (KDE Service Deck D-Bus helper) as a declarative Nix derivation.
  - Declaratively managed Service Deck menu structure (`plasma-service-deck.json`) and Digital circuit simulator options (`.digital.cfg`).
- **Declarative KDE Plasma Management (Tier 3 via `plasma-manager`):**
  - Integrated `github:nix-community/plasma-manager` into flake inputs and user module (`home-manager.sharedModules`).
  - Declaratively managed keyboard repeat delay/rate (`input.keyboard`), virtual desktops (`kwin.virtualDesktops`), and global desktop/media/window shortcuts (`programs.plasma.shortcuts`).
  - Configured hardware input profiles in `configFile.kcminputrc` (Keychron M6, Razer DeathAdder Essential, Asus Touchpad).
  - Migrated PowerDevil AC/battery power state synchronization scripts from static symlinks to `configFile."powerdevilrc"` so PowerDevil retains runtime state without file permission collisions.
  - Configured Wayland virtual keyboard, Xwayland scaling, and `kdeglobals` accent colors declaratively.
- **Modularization of User Profile (`modules/users/nnon/`):**
  - Partitioned the monolithic user manifest into decoupled domain modules under [`modules/users/nnon/`](file:///home/nnon/lunar-witches/modules/users/nnon):
    - [`default.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/default.nix): System user account, typed options, and Home Manager module composition.
    - [`shell.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/shell.nix): Fish, Bash, shell aliases, session variables, Btop, and Fastfetch.
    - [`development.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/development.nix): VS Code profiles/settings/extensions, Git signing, GPG/agent, and SSH client config.
    - [`desktop.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/desktop.nix): XDG user dirs, MIME applications, user packages, Service Deck, and Digital simulator settings.
    - [`plasma.nix`](file:///home/nnon/lunar-witches/modules/users/nnon/plasma.nix): KDE Plasma shortcuts, KWin virtual desktops, input device profiles, and PowerDevil hooks.
