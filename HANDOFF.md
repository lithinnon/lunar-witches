# Multi-Agent Handover Ledger (`lunar-witches`)

> **Contract:** Both **Antigravity** and **Pi (MiMo v2.6)** MUST read this file upon session start/swap-in, and update it before yielding control to the user. See [`AGENTS.md`](file:///home/nnon/lunar-witches/AGENTS.md#7-multi-agent-handover-protocol-antigravity--pi--mimo-v26) for the full protocol.

---

## 1. Active State Snapshot

- **Last Active Agent:** Antigravity
- **Timestamp:** 2026-10-09 13:23 +07:00
- **Host Target:** `lunar-qualia` (AMD Ryzen AI Max+ 392, Radeon 8060S, 32GB UMA)
- **Current Branch:** `master`
- **Active Git Commit:** `7d627ba` (`feat(core): add zip and unzip to systemPackages`)
- **Working Tree:** Clean (all changes committed)
- **Live NixOS Generation:** Generation 101 (`nh os switch` candidate built and ready at `/nix/store/6hyfh3nsq5a1h1wal9q05zcyx4p7sa25-nixos-system-lunar-qualia-26.11.20261006.151fa4e`)

---

## 2. Recent Work & Context

### Completed by Pi (MiMo v2.6):
1. **Added `llama-swap` to Prose Suite (`647c5a4`):** Packaged `llama-swap` alongside `llama-cpp-vulkan` in `modules/suites/ai/prose.nix`.
2. **Configured XDG Skeleton & Boulesis Model (`c3f42ef`, `77dccde`):** Declared `creative/boulesis-v2.1-headtune` with `ttl=1200s`, Vulkan0 compute device, and DeepSeek reasoning flags.
3. **User Service & AI Service Deck (`a0f5759`):** Wired `llama-swap.service` into user systemd units and registered it on the AI Service Deck group.
4. **Refactored Config to Typed Nix (`9fefc91`):** Converted raw text YAML into `pkgs.formats.yaml` generated from typed Nix attributes.

### Completed by Antigravity:
1. **ROCm 10.1 (TheRock) In-Tree Derivation (`pkgs/rocm-therock`):**
   - Packaged AMD's official stable prebuilts with overridable `version ? "10.1.0"` and strictly required `gfx`.
   - Injected CRT objects, include dirs, and library rpaths into `rocm.cfg` and `amdclang++.cfg` for zero-flag compilation.
2. **Capability Suite Integration (`modules/suites/ai/rocm.nix`):**
   - Generalized all version strings (`version`, `torchVersion`, `tritonVersion`) dynamically derived from `rocmPkg.version`.
   - Injected ROCm into `environment.systemPackages` and `programs.nix-ld.libraries` for unpatched binaries and wheels.
3. **Pattern B Shared Virtual Environment (`~/.local/share/rocm/venv-${gfx}`):**
   - `torch-dev` automatically prioritizes a project-local `./.venv` if present, otherwise auto-activates `~/.local/share/rocm/venv-${gfx}`.
   - On first run, `torch-dev` automatically bootstraps the shared environment once. All subsequent launches in any folder activate instantly (0.01s).
   - `init-rocm-venv` supports `--flash-attn` (and `--with-flash-attn`) to automatically compile and install Flash Attention 2 during environment bootstrap.
   - Live hardware validated on Radeon 8060S (`gfx1151`) with standard and packed QKV forward passes (`flash_attn_func`, `flash_attn_qkvpacked_func`).
   - Exported `flake.lib.mkRocmDevShells` to allow instantiating shells for any GPU architecture.
4. **Host Leaf Composition (`hosts/lunar-qualia/default.nix`):**
   - Configured `suites.ai.rocm.enable = true; suites.ai.rocm.gfx = "gfx1151";`.
   - Verified dry-run evaluation and built generation locally via `nh os build`.
5. **Populated Precomputed SRI Hashes for All Architectures (`pkgs/rocm-therock/default.nix`):**
   - Sourced and verified official SHA-256 SRI hashes directly from AMD's stable distribution tarballs.
   - Fully covered AMD APUs (`gfx1150`, `gfx1151`, `gfx1152`, `gfx1153`), RDNA 3 (`gfx1100`–`gfx1103`, `gfx110X-all`), RDNA 2 (`gfx1030`–`gfx1035`, `gfx103X-all`), RDNA 1 (`gfx1010`–`gfx1012`, `gfx101X-dgpu`), RDNA 4 (`gfx1200`–`gfx1201`, `gfx120X-all`), CDNA (`gfx908`, `gfx90a`, `gfx942`, `gfx94X-dcgpu`, `gfx950`, `gfx125X-dcgpu`), and universal `multiarch`.
   - Zero configuration required for users targeting any of these architectures without needing to pass an explicit `hash`.
6. **Added Universal Archive Utilities (`modules/core/default.nix`):**
   - Declared `zip` and companion `unzip` in baseline `environment.systemPackages`.

---

## 3. In-Flight Tasks & Next Immediate Steps

- [x] Integrate `pkgs/rocm-therock` (GFX-agnostic, strictly un-defaulted `gfx`).
- [x] Create 3 squashed devShells (`hip-runtime`, `hip-dev`, `torch-dev`) with anti-drift constraints and Flash Attention helpers.
- [x] Wire `suite-ai-rocm` into `lunar-qualia` and test local build (`nh os build`).
- [x] Populate precomputed SRI hashes for all supported ROCm TheRock architectures.
- [ ] *(Optional / Next)*: Activate live system generation via `nh os switch` (prompts via `ksshaskpass`).

---

## 4. Architectural Notes & Gotchas for the Incoming Agent

1. **Privilege Escalation:**
   Always use `sudo -A` and `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` for system switching. The system uses KDE Plasma's `ksshaskpass` graphical dialog.
2. **`gfx` Strict Invariant:**
   `pkgs.rocm-therock` and `suites.ai.rocm.gfx` must NEVER default to any architecture. If invoked without an explicit architecture string, it throws an error / fails assertion by design.
3. **Python & Wheel Resolution:**
   The official TheRock aggregate wheel index is `https://stable.repo.amd.com/rocm/whl-next`. PyTorch wheels in TheRock are split: `torch` is architecture-neutral host code, while `amd-torch-device-${gfx}` carries the GPU kernel packs. In `torch-dev`, `PIP_CONSTRAINT` / `UV_CONSTRAINT` prevents third-party packages from replacing ROCm packages with PyPI CPU wheels.
