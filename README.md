# lunar-witches

> **Dendritic NixOS Configuration** powered by `flake-parts` and `home-manager`.  
> **Primary Host:** `lunar-qualia` (ASUS TUF Gaming A14 FA401EA)

---

## 1. Hardware & Platform Profile

- **Processor:** AMD Ryzen AI Max+ 392 (16C/32T Zen 5)
- **Graphics:** AMD Radeon 8060S (40 CUs RDNA 3.5 / `gfx1151`)
- **NPU Accelerator:** AMD XDNA 2 AIE2p (`amdxdna` over `/dev/accel/accel0`, 50 TOPS)
- **Memory Architecture:** 32GB LPDDR5X-8533 Unified Memory (UMA) with dynamic TTM allocation
- **Kernel & Desktop:** Linux 7.3 (CachyOS BORE Zen 4) + KDE Plasma 6.3 (Wayland)
- **Storage Layout:** BTRFS with subvolumes (`@`, `@home`, `@nix`, `@snapshots`, `@log`, `@swap`)

---

## 2. Dendritic Architecture (6 Tiers)

The repository follows a decoupled dendritic pattern where hosts compose modular traits:

```
lunar-witches/
├── hosts/          # Tier 6: Host compositions and physical hardware manifests
├── modules/
│   ├── core/       # Tier 1: Universal baseline (Nix, nh, sudo, locale, nix-ld)
│   ├── roles/      # Tier 2: Form factor roles (laptop, desktop, server, boot)
│   ├── hardware/   # Tier 3: Silicon & bus traits (AMD CPU/GPU, zswap, ASUS OEM)
│   ├── features/   # Tier 4: Opt-in background services (amdgpu-boost, sops, syncthing)
│   ├── suites/     # Tier 5: Software suites (plasma, apps, gaming, ai, development)
│   └── users/      # Declarative Home Manager user profiles (nnon)
├── pkgs/           # In-tree derivations & overlays (mem-ttm, amdgpu-boost, app)
├── shells/         # Reusable devShells (default, amd-ai-dev, loom-dev)
└── retrospects/    # Indexed knowledge base (ADRs, manuals, proofs, postmortems)
```

---

## 3. Development Shells

Enter reproducible environments directly without container overhead:

```bash
# Core Flake development (nixd LSP, nixfmt)
nix develop

# AMD AI compute stack (ROCm 10.1, PyTorch 2.12, Flash Attention 2, NPU tools)
nix develop .#amd-ai-dev

# ROCm Loom & HRX heterogeneous compute (Rust 1.99, Clang, ccache, CMake, Loom DSL)
nix develop .#loom-dev
```

---

## 4. Daily Operations

```bash
# Format codebase
nix fmt

# Dry-run evaluation test (no root required)
nix build .#nixosConfigurations.lunar-qualia.config.system.build.toplevel --dry-run

# Build and cache generation locally
nh os build /home/nnon/lunar-witches

# Activate system configuration (triggers graphical ksshaskpass)
nh os switch /home/nnon/lunar-witches

# Clean older generations (keeps last 3)
nh clean all --keep 3
```

---

## 5. Knowledge Base & History

Detailed technical documentation is indexed in [`retrospects/README.md`](file:///home/nnon/lunar-witches/retrospects/README.md):
- **Architecture Decision Records:** [`retrospects/adr/`](file:///home/nnon/lunar-witches/retrospects/adr/) (ADRs 0001–0016)
- **Living Manuals:** [`retrospects/manuals/amd-ai-compute-stack.md`](file:///home/nnon/lunar-witches/retrospects/manuals/amd-ai-compute-stack.md) & [`retrospects/manuals/adding-hosts.md`](file:///home/nnon/lunar-witches/retrospects/manuals/adding-hosts.md)
- **Empirical Proofs:** [`retrospects/proofs/`](file:///home/nnon/lunar-witches/retrospects/proofs/) (NPU IRON, Flash Attention, Loom, LLM proofs)
- **Historical Migration Runbook:** [`retrospects/history/2026-09-30-fedora-to-nixos-migration.md`](file:///home/nnon/lunar-witches/retrospects/history/2026-09-30-fedora-to-nixos-migration.md)
