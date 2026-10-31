# ADR 0015: In-Tree ROCm 10.1 (TheRock) Packaging & Strict DevShell Compiler Isolation

> **Status:** Accepted  
> **Date:** 2026-10-09  
> **Scope:** AI Acceleration, Compilers & Developer Shells  

---

## 1. Context & Problem

Enabling modern AMD GPU AI compute (ROCm 10.1, PyTorch 2.12, Flash Attention 2) on NixOS presents several challenges:
1. **Flake/Nixpkgs Divergence:** Upstream Nixpkgs ROCm packages frequently lag behind official AMD releases, require recompiling hundreds of gigabytes of LLVM from source, and lack architecture-specific optimizations for Strix Halo (`gfx1151`).
2. **Global PATH Pollution (`exposeCompilers`):** Exposing heavy compiler suites (`amdclang++`, `hipcc`, `binutils-wrapper`) on the global system `$PATH` pollutes unrelated host CMake and native C/C++ builds, risks silent toolchain collisions, and bloats the system closure.
3. **Python Wheel Incompatibilities:** PyPI default wheels for PyTorch only target CUDA or CPU, frequently replacing ROCm builds during unpinned `pip install` commands.

## 2. Decision

1. **In-Tree ROCm Packaging (`pkgs/rocm-therock`):**
   - Packaged official AMD stable distribution tarballs with strictly parameterized architecture selection (`gfx`).
   - Populated verified precomputed SRI hashes across all AMD APU, RDNA, and CDNA generations.
   - Spliced CRT objects, glibc include headers, and library rpaths directly into `rocm.cfg` and `amdclang++.cfg` for zero-flag compilation.
2. **Three-Tier Architecture & DevShell Isolation:**
   - **Global Host (`environment.systemPackages`):** Exposes only `rocm-diagnostics` (`rocminfo`, `amd-smi`, `rocm_agent_enumerator`).
   - **Dynamic Linker (`programs.nix-ld.libraries`):** Retains ROCm shared libraries to support unpatched binaries and wheels.
   - **Compilers & Developer Tools (`shells/amd/dev.nix`):** Full compilers, headers, CMake configs, and Python virtual environment bootstrap tools (`init-rocm-venv`) are strictly confined to the `amd-dev` shell.
   - **Elimination of `exposeCompilers`:** Removed the global compiler toggle entirely to enforce strict isolation.
3. **Pattern B Shared Virtual Environment & Flash Attention:**
   - Devshell provides instant startup by prioritizing `./.venv` if present, falling back to a cached `~/.local/share/rocm/venv-${gfx}`.
   - Automated bootstrap script (`init-rocm-venv`) handles official AMD wheel constraints and `--flash-attn` compilation.

## 3. Consequences

- System closure reduced by ~200 MiB and store paths cleaned up.
- Host CMake and C/C++ builds remain isolated from ROCm compiler overrides.
- Instant, zero-friction developer experience inside `nix develop .#amd-dev`.
