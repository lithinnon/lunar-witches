# lunar-witches

Dendritic NixOS configuration for `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S).

---

## 1. Architecture

Six-tier decoupled dendritic tree (see [ADR 0010](./retrospects/adr/0010-six-tier-dendritic-decomposition.md)):

```
lunar-witches/
├── hosts/          # Host leaf compositions and partition manifests
├── modules/
│   ├── core/       # Universal baseline (Nix, nh, sudo, locale, nix-ld)
│   ├── roles/      # Form factor roles (laptop, desktop, server, boot)
│   ├── hardware/   # Hardware and silicon traits
│   ├── features/   # Opt-in services (sops, syncthing, chulawifi)
│   ├── suites/     # Software suites (plasma, apps, gaming, ai, development)
│   └── users/      # Declarative Home Manager user profiles
├── pkgs/           # In-tree derivations (mem-ttm, triellama, hrx-runtime)
├── shells/         # Flake devShells (default, amd-dev, amd-runtime)
└── retrospects/    # Indexed knowledge base (ADRs, manuals, proofs, postmortems)
```

---

## 2. Development Shells

- `nix develop`: Core Flake hacking (`nixd`, `nixfmt`).
- `nix develop .#amd-dev`: Unified AMD AI Studio (ROCm 10.1, PyTorch 2.12, Flash Attention 2, Loom, HRX, XRT, Rust toolchain).
- `nix develop .#amd-runtime`: Lightweight AMD runtime & diagnostics (`rocminfo`, `xrt-smi`, HRX toggles).

---

## 3. Daily Operations

```bash
nix fmt                                                                             # Format syntax
nix build .#nixosConfigurations.lunar-qualia.config.system.build.toplevel --dry-run  # Dry evaluation
nh os build /home/nnon/lunar-witches                                                # Build generation
nh os switch /home/nnon/lunar-witches                                               # Activate generation
nh clean all --keep 3                                                               # Prune old generations
```

---

## 4. Documentation

Technical documentation is indexed in [`./retrospects/README.md`](./retrospects/README.md):
- **ADRs:** [`./retrospects/adr/`](./retrospects/adr/)
- **Manuals:** [`./retrospects/manuals/amd-ai-compute-stack.md`](./retrospects/manuals/amd-ai-compute-stack.md) & [`./retrospects/manuals/adding-hosts.md`](./retrospects/manuals/adding-hosts.md)
- **Proofs:** [`./retrospects/proofs/`](./retrospects/proofs/)
- **Troubleshooting:** [`./retrospects/troubleshooting/nixos-desktop-quirks.md`](./retrospects/troubleshooting/nixos-desktop-quirks.md)
