# Technical Retrospects & Architecture Records (`lunar-witches`)

> **Repository:** `lunar-witches`  
> **Framework:** NixOS 26.11 (Zokor) managed via dendritic Nix Flakes  
> **Deployment Target:** `lunar-qualia` (ASUS TUF Gaming A14 FA401EA, AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB LPDDR5X)  

---

## Directory Taxonomy & Structure

To ensure long-term maintainability, clean AI agent retrieval, and clear separation of concerns, documentation in this directory is categorized into 6 specialized domains:

```
retrospects/
├── adr/               # Architectural Decision Records (1 decision per file)
├── postmortems/       # Incident root cause analyses and timelines
├── proofs/            # Empirical silicon benchmarks & hardware test runs
├── manuals/           # Living technical references & architecture manuals
├── troubleshooting/   # Operational runbooks & known quirks
└── history/           # One-time milestone logs & migration chronicles
```

---

### 1. Architectural Decision Records (`adr/`)
Immutable records capturing the **Context**, **Decision**, and **Consequences** of technical and architectural choices.

| ADR | Title | Date | Scope |
| :--- | :--- | :--- | :--- |
| [`0001`](./adr/0001-dendritic-flake-pattern.md) | Dendritic Flake Structure Powered by Flake-Parts | 2026-09-30 | Repository Architecture |
| [`0002`](./adr/0002-cachyos-bore-kernel.md) | CachyOS BORE Zen 4 Kernel & BTRFS Storage Layout | 2026-09-30 | Kernel & Storage |
| [`0003`](./adr/0003-toolchains-and-nix-ld-boundary.md) | Native Applications over Flatpak & Dynamic Binary Compatibility via `nix-ld` | 2026-09-30 | Application Ecosystem |
| [`0004`](./adr/0004-intree-derivations-and-overlays.md) | In-Tree Custom Derivations & Flake Overlay Pattern (`pkgs/`) | 2026-09-30 | Package Management |
| [`0005`](./adr/0005-aagl-binary-cache-and-ntsync.md) | Anime Game Launcher (AAGL) & Binary Cache Strategy | 2026-09-30 | Gaming Suite |
| [`0006`](./adr/0006-out-of-tree-user-apps-boundary.md) | Repository Scope & Boundaries: Out-of-Tree User Applications (BullVPN Boundary) | 2026-09-30 | Scope & Boundaries |
| [`0007`](./adr/0007-multi-user-git-safe-directory.md) | Multi-User Privilege Boundaries & Git `safe.directory` | 2026-09-30 | Git & Privileges |
| [`0008`](./adr/0008-secrets-management-boundary.md) | Secrets Management & The World-Readable `/nix/store` Boundary | 2026-09-30 | Security & Secrets |
| [`0009`](./adr/0009-custom-protocol-handlers-sgdboop.md) | Custom Desktop Protocol Handlers & Steam Artwork (`sgdboop`) | 2026-09-30 | Desktop Integration |
| [`0010`](./adr/0010-six-tier-dendritic-decomposition.md) | Six-Tier Dendritic Decomposition & Parametric Hardware Traits | 2026-10-02 | System Hierarchy |
| [`0011`](./adr/0011-silicon-quirks-and-upstream-alignment.md) | Silicon Quirks, Client Automation & Upstream Alignment | 2026-10-02 | Hardware Quirks |
| [`0012`](./adr/0012-chulawifi-enterprise-secrets.md) | Enterprise 802.1x Authentication & Campus Wi-Fi (`ChulaWiFi`) | 2026-10-06 | Networking & 802.1x |
| [`0013`](./adr/0013-hardened-openssh-and-agent.md) | Hardened OpenSSH Daemon & Passphrase-Backed SSH Agent Integration | 2026-10-06 | Security & Remote Access |
| [`0014`](./adr/0014-declarative-home-and-plasma-manager.md) | Declarative User Environment & KDE Plasma Management via `plasma-manager` | 2026-10-06 | User Profile & Desktop |
| [`0015`](./adr/0015-rocm-therock-and-devshell-isolation.md) | In-Tree ROCm 10.1 (TheRock) Packaging & Strict DevShell Compiler Isolation | 2026-10-09 | AI & Compilers |
| [`0016`](./adr/0016-unlimited-memlock-for-hardware-accelerators.md) | Unlimited Locked Memory (`memlock`) for Hardware Accelerators | 2026-10-09 | Kernel Limits & DMA |

---

### 2. Incident Post-Mortems (`postmortems/`)
Detailed root cause analyses, failure timelines, and declarative remediations for complex incidents.

- [`2026-10-06-fwupd-polkit-activation-race.md`](./postmortems/2026-10-06-fwupd-polkit-activation-race.md): Race condition between `polkit.service` and `fwupd.service` during switch activation causing exit code 4.
- [`2026-10-09-amdxdna-ring-buffer-eagain.md`](./postmortems/2026-10-09-amdxdna-ring-buffer-eagain.md): AMDXDNA driver ring buffer allocation failure (`err=-11 EAGAIN`) due to PAM/systemd locked memory (`RLIMIT_MEMLOCK`) limits.

---

### 3. Empirical Silicon Proofs (`proofs/`)
Reproducible lab runs, hardware traces, and validation benchmarks on physical silicon.

- [`2026-10-09-amd-xdna-iron-xrt-verification.md`](./proofs/2026-10-09-amd-xdna-iron-xrt-verification.md): Physical AMD XDNA 2 AIE2p NPU execution proof using MLIR-AIE, IRON JIT compiler, and matched XRT 2.21.75 runtime on 4 tiles.
- [`2026-10-09-rocm-loom-libamdf-silicon-execution.md`](./proofs/2026-10-09-rocm-loom-libamdf-silicon-execution.md): Live GPU & NPU silicon execution proof using ROCm Loom compiler and `libamdf` direct Linux DRM runner (`/dev/accel/accel0`).
- [`2026-10-09-pytorch-flash-attention-live-hrx-execution.md`](./proofs/2026-10-09-pytorch-flash-attention-live-hrx-execution.md): Live PyTorch 2.12 autograd training & Flash Attention 2 execution proof on Radeon 8060S GPU running over HRX runtime (`libamdhip64.so`).
- [`2026-10-25-qwen-26b-a4b-token-efficient-qad-proof.md`](./proofs/2026-10-25-qwen-26b-a4b-token-efficient-qad-proof.md): Empirical proof of Token-Efficient High-Kurtosis Micro-Calibration (QAD, -12.5% PPL to 2.8789) and Native 1-layer MTP (`blk.40.nextn`, 73.8 t/s) on Radeon 8060S.

---

### 4. Living Architecture Manuals (`manuals/`)
Authoritative operational guides and developer manuals kept continuously synchronized with the active codebase.

- [`amd-ai-compute-stack.md`](./manuals/amd-ai-compute-stack.md): Master architectural reference for the entire AMD AI ecosystem (ROCm 10.1, PyTorch, Flash Attention 2, XRT, IRON, Loom, and HRX).
- [`adding-hosts.md`](./manuals/adding-hosts.md): Procedure for adding and composing new target machines in the dendritic flake.

---

### 5. Troubleshooting Runbooks (`troubleshooting/`)
Operational runbook of known desktop quirks, edge cases, and solutions encountered on NixOS.

- [`nixos-desktop-quirks.md`](./troubleshooting/nixos-desktop-quirks.md): Edge-case reference (ESP random seed, `nh` vs `nix.gc`, Home Manager backup extension, Fish `$PATH`, SDDM wallpaper persistence, Equibop SIGILL, etc.).

---

### 6. Historical Chronicles (`history/`)
Immutable historical migration records and preparatory RFCs.

- [`2026-09-30-fedora-to-nixos-migration.md`](./history/2026-09-30-fedora-to-nixos-migration.md): Original migration journey from Fedora 44 to NixOS 26.11 on ASUS TUF Gaming A14 hardware.
- [`2026-10-09-amd-xdna-npu-readiness-rfc.md`](./history/2026-10-09-amd-xdna-npu-readiness-rfc.md): Initial exploratory RFC on AMD XDNA NPU architecture and system readiness.
- [`2026-10-09-rocm-loom-hrx-architecture-rfc.md`](./history/2026-10-09-rocm-loom-hrx-architecture-rfc.md): Initial exploratory RFC on ROCm Loom compiler and HRX system architecture.
- [`2026-10-session-ledger.md`](./history/2026-10-session-ledger.md): Archived session ledger (items 1–31) graduated from `HANDOFF.md` covering ROCm 10.1, XDNA NPU, Loom, beellama, and Digital tooltips.
- [`2026-10-session-chronicles.md`](./history/2026-10-session-chronicles.md): Authoritative extracted institutional knowledge from Pi and Antigravity sessions covering 9 core thematic domains (ChulaWiFi secrets, container purge, Plasma 6 widgets, Boulesis 64k `snc8` cache, ROCm 10.1 isolation, AMD XDNA 2 NPU execution, ROCm Loom direct DRM, system tuning, and multi-agent memory architecture).
