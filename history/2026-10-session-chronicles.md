# Historical Session Chronicles & Knowledge Index (October 2026)

> **Context & Purpose:**  
> This chronicle captures, synthesizes, and indexes the foundational architectural decisions, hardware proofs, system quirks, and design evolutions established during the multi-week pairing sessions between the system owner (`nnon`) and AI agents (**Google Antigravity** and **Earendil Pi / MiMo v2.6**).  
>
> Rather than forcing future agents or fresh chat contexts to parse multi-megabyte raw `.jsonl` transcript logs (which consume excessive tokens and lack structured taxonomy), this document serves as the **authoritative extracted institutional memory** for the repository.

---

## 1. Provenance & Session Metadata

| Attribute | Pi Coding Agent Session | Antigravity CLI Session |
| :--- | :--- | :--- |
| **Session Lineage ID** | `01a10a7f-7d9a-753c-9b68-372aa214bb10` | `f73d4a6a-84c7-4614-9114-d72055951b42` |
| **Primary Model / Harness** | Kimi K2.6 / MiMo v2.6 via Pi CLI | Google Antigravity via `agy` CLI |
| **Active Date Window** | 2026-10-05 – 2026-10-09 | 2026-09-30 – 2026-10-11 |
| **Primary System Targets** | NixOS 26.11 (`lunar-qualia`), Linux 7.2.8-cachyos | NixOS 26.11 (`lunar-qualia`), Linux 7.2.8-cachyos |
| **Generations Covered** | Generations 70 – 95 | Generations 1 – 70, 96 – 109 |
| **Raw Forensic Path (Cold)** | `~/.config/pi/agent/sessions/--home-nnon-lunar-witches--/2026-10-05T05-18-09-818Z_01a10a7f-7d9a-753c-9b68-372aa214bb10.jsonl` | `~/.gemini/antigravity-cli/brain/f73d4a6a-84c7-4614-9114-d72055951b42/.system_generated/logs/transcript.jsonl` |

---

## 2. Thematic Extraction Index

1. [Enterprise 802.1x Networking & Secrets Boundary (`ChulaWiFi`)](#thematic-domain-1-enterprise-8021x-networking--secrets-boundary-chulawifi)
2. [Container Decommissioning & In-Tree Binary Packaging](#thematic-domain-2-container-decommissioning--in-tree-binary-packaging)
3. [Desktop Integration, Plasma 6 Widgets & MIME Architecture](#thematic-domain-3-desktop-integration-plasma-6-widgets--mime-architecture)
4. [Local AI Inference & Prose Architecture (`sillytavern`, `llama-swap`, `beellama.cpp`)](#thematic-domain-4-local-ai-inference--prose-architecture)
5. [In-Tree ROCm 10.1 (TheRock) Packaging & 3-Tier DevShell Isolation](#thematic-domain-5-in-tree-rocm-101-therock-packaging--3-tier-devshell-isolation)
6. [AMD XDNA 2 AIE2p NPU Silicon Execution & Driver Post-Mortem](#thematic-domain-6-amd-xdna-2-aie2p-npu-silicon-execution--driver-post-mortem)
7. [ROCm Loom (`libamdf`) & Direct DRM Accelerator Architecture](#thematic-domain-7-rocm-loom-libamdf--direct-drm-accelerator-architecture)
8. [System Tuning, Closure Shedding & Declarative Environment Quirks](#thematic-domain-8-system-tuning-closure-shedding--declarative-environment-quirks)
9. [Cross-Agent & Cross-Session Continuity Protocol](#thematic-domain-9-cross-agent--cross-session-continuity-protocol)

---

### Thematic Domain 1: Enterprise 802.1x Networking & Secrets Boundary (`ChulaWiFi`)

- **Origin Session:** Pi Session (`01a10a7f-7d9a-753c-9b68-372aa214bb10`), Turns 5–240, 480–604.
- **Architectural Scope:** `modules/features/chulawifi.nix`, `hosts/lunar-qualia/default.nix`, [`ADR 0012`](../../retrospects/adr/0012-chulawifi-enterprise-secrets.md).

#### Context & Problem
Connecting to Chulalongkorn University's campus enterprise Wi-Fi (`ChulaWiFi` / `eduroam`) requires WPA2-Enterprise 802.1x with EAP-PEAP / MSCHAPv2 authentication. NixOS's declarative configuration model poses two critical challenges:
1. **Nix Store Leakage:** Writing network profiles with cleartext credentials into `/etc/NetworkManager/system-connections/` via Nix derivations bakes secrets into the world-readable `/nix/store` (`chmod -R a+r`).
2. **RADIUS Server Quirks:** The campus RADIUS infrastructure uses legacy TLS 1.0 / MSCHAPv2 handshakes rejected by default modern OpenSSL configurations.

#### Technical Evolution & Key Discoveries
1. **Adoption of `chula-flake`:**  
   Replaced ad-hoc, hardcoded NetworkManager definitions with the modular upstream flake input `inputs.chula.nixosModules.wifi` (`github:MiniHarinn/chula-flake`).
2. **RAM-Only Secrets Substitution:**  
   Credentials reside in a `chmod 600` root-owned environment file at `~/.config/chula/environment` containing `CHULA_WIFI_IDENTITY` and `CHULA_WIFI_PASSWORD`. NetworkManager utilizes `ensureProfiles.environmentFiles` to substitute secrets into ephemeral keyfiles in RAM (`/run/NetworkManager/system-connections/`) at boot time. Zero secrets touch `/nix/store` or persistent disk.
3. **Legacy RADIUS Crypto Flags:**  
   The authentication handshake requires `phase1-auth-flags = 32` (0x20) and `openssl-ciphers = "DEFAULT@SECLEVEL=0"` to succeed against the university RADIUS endpoint.
4. **The NM Keyfile Backslash Escaping Bug:**  
   *Discovery:* On subsequent reboots, 802.1x authentication repeatedly failed with "cannot be interpreted".  
   *Root Cause:* NetworkManager keyfiles strictly require literal backslashes (`\`) in credentials (common in Windows domain usernames like `DOMAIN\user`) to be escaped as `\\`. However, `envsubst` writes the password unescaped, and systemd's `EnvironmentFile=` parser collapses `\\` back into `\`.  
   *Resolution:* `modules/features/chulawifi.nix` post-processes generated keyfiles via an activation script that re-escapes `password=` lines and issues `nmcli connection reload`.

---

### Thematic Domain 2: Container Decommissioning & In-Tree Binary Packaging

- **Origin Session:** Pi Session (`01a10a7f-7d9a-753c-9b68-372aa214bb10`), Turns 716–830.
- **Architectural Scope:** `modules/suites/desktop/apps.nix`, [`AGENTS.md`](../../AGENTS.md#1-system-identity--core-invariants).

#### Context & Problem
During the Fedora-to-NixOS migration, legacy workflows relied on Podman, Distrobox, and containerized tools for custom desktop software. The user requested setting up Distrobox on NixOS to run Ubuntu-based containers.

#### Technical Evolution & Key Discoveries
1. **Container Tooling Pitfalls on NixOS:**  
   Testing Distrobox on NixOS encountered image short-name resolution failures (`ubuntu:26.04` failing due to missing unqualified-search registries in `/etc/containers/registries.conf`) and storage driver friction on BTRFS subvolumes.
2. **The "Zero-Container Invariant" Established:**  
   The user and Pi decided to abandon Distrobox and Podman entirely. Containers introduce opaque layers, storage bloat, and mutable states that counteract NixOS's reproducibility. The system-level container modules were completely purged.
3. **In-Tree Packaging Strategy:**  
   Rather than wrapping software in a container or relying on unmanaged AppImages, standalone applications are packaged declaratively as native in-tree Nix derivations, exposed via overlays and installed declaratively via `home.packages`.
4. **Plain AppImage Fallback:**  
   For other ad-hoc single-file executables, a minimal `appimage-run` was provisioned in `modules/suites/desktop/apps.nix` with an `application/vnd.appimage` desktop double-click MIME handler—deliberately configured without extra FHS packages (no webkit chain) to prevent closure bloat.

---

### Thematic Domain 3: Desktop Integration, Plasma 6 Widgets & MIME Architecture

- **Origin Session:** Pi Session (`01a10a7f-7d9a-753c-9b68-372aa214bb10`), Turns 255–290, 841–909.
- **Architectural Scope:** `modules/users/nnon/desktop.nix`, `pkgs/service-deck-helper`, `pkgs/plasma-widget-servicedeck`, `pkgs/plasma-widget-amdgpuboost`.

#### Context & Problem
KDE Plasma 6 Wayland desktop integration broke for custom system widgets (Service Deck and AMD GPU Booster) and digital logic circuit file associations.

#### Technical Evolution & Key Discoveries
1. **Digital Logic Suite & MIME Associations:**  
   - Linked both `.dig` (`application/x-digital` circuit schematics) and `.tru` (`text/x-digital` truth table specifications) to `digital.desktop` via Home Manager `xdg.mimeApps.defaultApplications`.
   - Added an XDG desktop entry `Digital++` with the official Digital icon executing `nix run github:MiniHarinn/digital-egro` for enhanced digital logic exploration.
   - Added user alias `plasma-menu-restart` (`systemctl --user restart plasma-plasmashell.service`) for rapid Wayland shell recovery.
2. **Plasma 6 Wayland Widget Absolute Path Invariant:**  
   *Discovery:* Custom plasmoids (`service-deck`, `amdgpuboost`) failed to display metrics and controls under Plasma 6.  
   *Root Cause:* Under systemd-managed Plasma 6 sessions, applets executing helper scripts via relative paths or relying on `PATH` resolution fail because Plasmashell spawns within a stripped environment.  
   *Resolution:* Custom plasmoids were converted into in-tree C++ derivations in `pkgs/` with hardcoded absolute Nix store paths to their helper executables (`service-deck-helper` and `amdgpu-boost`). Stale desktop entries at `~/.local/share/antigravity-app/` were purged.

---

### Thematic Domain 4: Local AI Inference & Prose Architecture

- **Origin Sessions:**  
  - Pi Session: Turns 859, 933–1086 (SillyTavern, `llama-swap`, YAML refactor).  
  - Antigravity Session: Turns 9784–10220 (`beellama.cpp`, `suite-ai-local`, Boulesis 64k `snc8` cache, ROCm HIP backend).
- **Architectural Scope:** `modules/suites/ai/prose.nix`, `modules/suites/ai/local.nix`, `pkgs/beellama`.

#### Context & Problem
The system requires an autonomous local LLM environment for creative prose and reasoning on the Strix Halo APU (AMD Radeon 8060S, 32GB unified LPDDR5X). The initial setup used upstream Nixpkgs `llama-cpp-vulkan`, which suffered from high closure overhead, lack of native ROCm HIP acceleration, and memory thrashing when handling large context windows.

#### Technical Evolution & Key Discoveries
1. **SillyTavern Systemd Service:**  
   - Packaged and managed via `services.sillytavern` listening on `0.0.0.0:8234`.
   - Hardened configuration: automatic browser launch disabled, whitelist disabled, multi-user authentication enabled.
   - Integrated as an AI service unit on the Plasma Service Deck.
2. **Declarative Typed Nix `llama-swap`:**  
   - Created user systemd service `llama-swap.service` listening on `127.0.0.1:8080`.
   - Replaced raw text template generation with typed Nix structures using `pkgs.formats.yaml` written to `$XDG_CONFIG_HOME/llama-swap.yml`.
   - Configured `creative/boulesis-v2.1-headtune` model runner with 1200s (20-minute) TTL and DeepSeek reasoning flags (`--reasoning-format deepseek`).
3. **Decoupled `suite-ai-local` & `beellama.cpp` Packaging:**  
   - Forked `beellama.cpp` (`lithinnon/beellama.cpp`) packaged as in-tree derivation `pkgs/beellama`, cutting 87.3 MiB of Nixpkgs closure.
   - Created dedicated `modules/suites/ai/local.nix` (`suite-ai-local`) composed into `hosts/lunar-qualia/default.nix`.
4. **The Boulesis 64k `snc8` Radix Memory Tier:**  
   Configured Boulesis 26B A4B in `llama-swap` with an optimized KV memory layout:
   - **Context Window:** 64,128 tokens (`--ctx-size 65536`).
   - **Quantization:** Sub-normalized non-linear 8-bit cache quantization (`--cache-type-k snc8 --cache-type-v snc8`).
   - **Tail Precision:** 1024 `bf16` tail tokens (`--kv-tail-tokens 1024 --kv-tail-type bf16`) preserving the full Sliding Window Attention (SWA) span at native bfloat16 fidelity.
   - **Storage Tiering:** 0-RAM cache overhead with 16 GiB NVMe radix disk tier (`--cache-ram 0 --cache-disk 16384 --cache-disk-hydrate`).
5. **Standard ROCm HIP Backend:**  
   Switched `beellama.cpp` backend from HRX to native standard ROCm HIP linked to TheRock 10.1 (`libamdhip64.so.7` and `hipBLAS`), parameterized via `suites.ai.local.backend = "rocm"`.

---

### Thematic Domain 5: In-Tree ROCm 10.1 (TheRock) Packaging & 3-Tier DevShell Isolation

- **Origin Session:** Antigravity Session (`f73d4a6a-84c7-4614-9114-d72055951b42`), Turns 6755–7815.
- **Architectural Scope:** `pkgs/rocm-therock`, `modules/suites/ai/rocm.nix`, `shells/rocm.nix`, [`ADR 0015`](../../retrospects/adr/0015-rocm-therock-and-devshell-isolation.md), [`Manual`](../../retrospects/manuals/amd-ai-compute-stack.md).

#### Context & Problem
Upstream Nixpkgs packages ROCm at legacy version 7.x, lacking support for RDNA 3.5 APUs (Strix Halo `gfx1151`). Installing unpatched prebuilt compiler toolchains (`hipcc`, `amdclang++`) onto global NixOS paths breaks CMake discovery, clashes with system Clang/GCC, and pollutes unrelated host builds.

#### Technical Evolution & Key Discoveries
1. **In-Tree Packaging (`pkgs/rocm-therock`):**  
   - Packaged AMD's official stable TheRock prebuilts with overridable `version ? "10.1.0"`.
   - **Invariant:** `gfx` parameter must NEVER default to any architecture—it must be explicitly specified by the host leaf.
   - Injected CRT startup objects, system include paths, and library rpaths into `rocm.cfg` and `amdclang++.cfg` to guarantee zero-flag compilation.
   - Populated verified SHA-256 SRI hashes for all AMD architectures (APUs `gfx1150`–`gfx1153`, RDNA 1–4, CDNA 1–3, multiarch).
2. **The 3-Tier Isolation Pattern:**  
   - **Tier 1 (Host System):** Only `rocm-diagnostics` wrapper is exported to `$PATH` (`rocminfo`, `amd-smi`, `rocm_agent_enumerator`). Global `ROCM_PATH`, `HIP_PATH`, and `CMAKE_PREFIX_PATH` environment variables were completely eliminated.
   - **Tier 2 (Dynamic Binaries):** Runtime shared libraries (`libamdhip64.so`, `libhipblas.so`) are registered in `programs.nix-ld.libraries` for unpatched binary and wheel compatibility.
   - **Tier 3 (Developer Environment):** Full compilers, headers, build launchers (`ccache`, `sccache`), and Python venv automation are quarantined strictly inside `amd-ai-dev` (`shells/rocm.nix`).
3. **Pattern B Shared Virtual Environment (`~/.local/share/rocm/venv-${gfx}`):**  
   - `torch-dev` automatically prioritizes a project-local `./.venv` if present, otherwise activates `~/.local/share/rocm/venv-${gfx}`.
   - Single-step bootstrap installing split AMD wheels (`torch` + `amd-torch-device-${gfx}`).
   - `--flash-attn` flag compiles Flash Attention 2 during bootstrap. Validated on Radeon 8060S (`gfx1151`) with bit-exact QKV forward passes (`flash_attn_func`).

---

### Thematic Domain 6: AMD XDNA 2 AIE2p NPU Silicon Execution & Driver Post-Mortem

- **Origin Session:** Antigravity Session (`f73d4a6a-84c7-4614-9114-d72055951b42`), Turns 7857–8659.
- **Architectural Scope:** `pkgs/xrt-amdxdna`, `modules/core/default.nix`, [`ADR 0016`](../../retrospects/adr/0016-unlimited-memlock-for-hardware-accelerators.md), [`Post-Mortem`](../../retrospects/postmortems/2026-10-09-amdxdna-ring-buffer-eagain.md), [`Proof`](../../retrospects/proofs/2026-10-09-amd-xdna-iron-xrt-verification.md).

#### Context & Problem
The AMD Ryzen AI Max+ 392 contains an AMD XDNA 2 neural processing unit (AIE2p, 32 tiles, 55+ TOPS). Attempting to initialize the NPU device ring buffer failed immediately with `err=-11 (EAGAIN)`.

#### Technical Evolution & Key Discoveries
1. **Kernel Driver Root Cause Analysis:**  
   On Linux 6.18+ / 7.2 CachyOS kernels, the upstream `amdxdna` kernel module allocates the command ring buffer via pinned direct memory access (DMA). When systemd or PAM limits locked memory (`RLIMIT_MEMLOCK`), `amdxdna_ring_create()` fails with `EAGAIN` (-11).
2. **Declarative Remediation:**  
   Configured unlimited locked memory across both interactive and system daemon scopes in `modules/core/default.nix`:
   - `security.pam.loginLimits = [{ domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }]`
   - `systemd.extraConfig = "DefaultLimitMEMLOCK=infinity"`
3. **In-Tree Packaging of `xrt-amdxdna` (`pkgs/xrt-amdxdna`):**  
   Built and packaged the matched AMD XRT 2.21.75 userspace plugin from official source, providing `pyxrt` Python bindings and CLI runtime support.
4. **Physical Silicon Verification Proof:**  
   Compiled MLIR-AIE and executed live IRON JIT compilation on physical NPU silicon (`/dev/accel/accel0`). Allocated host-device shared buffers via XRT BO, loaded compiled `.xclbin` onto 4 AIE tiles, and verified bit-exact tensor outputs.

---

### Thematic Domain 7: ROCm Loom (`libamdf`) & Direct DRM Accelerator Architecture

- **Origin Session:** Antigravity Session (`f73d4a6a-84c7-4614-9114-d72055951b42`), Turns 7992–9549.
- **Architectural Scope:** `shells/loom.nix`, [`RFC`](../../retrospects/history/2026-10-09-rocm-loom-hrx-architecture-rfc.md), [`Proofs`](../../retrospects/proofs/).

#### Context & Problem
AMD ROCm Loom introduces a unified heterogeneous runtime (HRX / `libamdf`) capable of dispatching compute graphs directly to both GPU (`gfx1151`) and NPU (`aie2p`) silicon via standard Linux Direct Rendering Manager (DRM) interfaces (`/dev/accel/accel0`), eliminating the heavy XRT userspace layer.

#### Technical Evolution & Key Discoveries
1. **Direct DRM Accelerator Execution:**  
   Proved that `libamdf` bypasses XRT entirely, directly opening and dispatching compute jobs to the Linux accelerator subsystem (`/dev/accel/accel0`).
2. **Three-Method Compilation & Execution (`shells/loom.nix`):**  
   Engineered developer tooling supporting three execution modalities:
   - `hrx-run`: `LD_PRELOAD` runtime shim enabling standard unpatched ROCm binaries to execute seamlessly over HRX.
   - `hrxcc`: Clang-based compiler wrapper generating native HRX binaries.
   - `loom-compile`: Pure Loom direct-to-metal AIE compiler.
3. **Silicon Proofs:**  
   - Live execution on `gfx1151` and `aie2p` silicon (`retrospects/proofs/2026-10-09-rocm-loom-libamdf-silicon-execution.md`).
   - PyTorch 2.12 autograd training & Flash Attention 2 execution over HRX runtime in `bfloat16` (`retrospects/proofs/2026-10-09-pytorch-flash-attention-live-hrx-execution.md`).
   - DevShells abstracted into `flake.lib.mkLoomDevShells`.

---

### Thematic Domain 8: System Tuning, Closure Shedding & Declarative Environment Quirks

- **Origin Sessions:** Both Pi and Antigravity Sessions.
- **Architectural Scope:** `modules/suites/desktop/plasma.nix`, `modules/users/nnon/desktop.nix`, `modules/core/default.nix`, [`Troubleshooting`](../../retrospects/troubleshooting/nixos-desktop-quirks.md).

#### Technical Discoveries & Fixes
1. **KDE PIM / Kontact Closure Shedding:**  
   Identified that default KDE Plasma desktop imports brought in extensive Akonadi, Kontact, and PIM dependencies. Explicitly disabled them in `modules/suites/desktop/plasma.nix`, reducing system closure size by 962 MiB.
2. **Digital Read-Only Symlink Tooltips Fix:**  
   Home Manager manages `~/.digital.cfg` as a symlink into `/nix/store`, which is read-only. Enabling "Wire tool tips" via the Digital GUI failed to persist across launches. Solved by declaratively injecting `<entry><string>wireToolTips</string><boolean>true</boolean></entry>` directly into `home.file.".digital.cfg"` (Generation 108).
3. **Declarative MCP Configuration:**  
   Migrated `~/.config/mcp/mcp.json` into Home Manager, ensuring tool server definitions persist declaratively.
4. **Universal Baseline Utilities:**  
   Added `zip` and `unzip` to `modules/core/default.nix` to prevent missing archive extraction utilities in standard developer workflows.
5. **Privilege Escalation & `NH_SUDO_ASKPASS` Invariant:**  
   - Proved that `nh os switch` uses internal elevation logic in Rust that ignores interactive shell prompts. Passing `-A` requires setting `NH_SUDO_ASKPASS=/run/current-system/sw/bin/ksshaskpass` (or `NH_SUDOOPTS="-A"`).
   - Configured graphically in `suite-desktop-plasma` and `users/nnon/default.nix` session variables, enforcing the invariant that AI agents never touch user passwords directly.
6. **User Profile Modularization & `plasma-manager`:**  
   - Refactored monolithic `modules/users/nnon.nix` into a 5-module dendritic tree: `default.nix` (account baseline), `shell.nix` (fish/bash/zsh), `development.nix` (git/compilers/tools), `desktop.nix` (xdg/mime/apps), and `plasma.nix` (KDE Plasma declarative theming).
   - Adopted `plasma-manager` for declarative panels, window rules, and keybindings.
7. **Hardware & Power Management Tooling:**  
   - Renamed `amd-ttm` to universal `mem-ttm` to provide vendor-agnostic TTM pool inspection across all GPU platforms.
   - Built in-tree `pkgs/sync-power-state` to dynamically align CPU governors and platform profiles between AC and battery operation.
8. **Global Wayland Productivity Shortcuts:**  
   Declared persistent global Wayland shortcuts in `modules/users/nnon/plasma.nix`:
   - `Super+Shift+L`: LocalSend
   - `Super+Shift+Q`: Kate Editor
   - `Super+Shift+D`: KCalc
   - `Super+Shift+C`: Google Calendar via user default browser
9. **NixOS MCP Tool Integration (`mcp-nixos`):**  
   - Evaluated `uvx` vs. declarative Nix flake provisioning for `mcp-nixos`.
   - Integrated `mcp-nixos` declaratively under MCP servers, providing AI agents with native package search and system evaluation capabilities.

---

### Thematic Domain 9: Cross-Agent & Cross-Session Continuity Protocol

- **Origin Sessions:** Antigravity Session Turns 10366–10415, Pi Session Turn 1086.
- **Architectural Scope:** `AGENTS.md`, `HANDOFF.md`, `retrospects/`.

#### The 4-Tier Hierarchical Memory Model

```
Tier 1: Active Chat Context Window (Ephemeral, volatile, bounded ~0-100k tokens)
   │
   ▼ (Session Compaction / Rotation)
Tier 2: Active Working Register (HANDOFF.md — sliding window strictly capped at ~100 lines)
   │
   ├─► Tier 3: Domain Knowledge Base & Indexed Chronicles (retrospects/ indexed via README.md)
   │
   ▼ (Milestone Graduation)
Tier 4: Archival Ledgers & Raw Forensics (retrospects/history/ & raw .jsonl session logs)
```

#### Protocol for Fresh Chat Sessions
1. **Cold Start:** Rather than attempting to ingest multi-megabyte `.jsonl` transcripts, a new session or swapped-in agent reads `HANDOFF.md` for the immediate state and `retrospects/README.md` (or this chronicle) for historical background.
2. **Compaction Ceremony:** When chat context grows large, completed items from `HANDOFF.md` graduate into `retrospects/history/2026-10-session-ledger.md`.
3. **Session Rotation Prompt:** The exiting agent provides a concise 1-line command:  
   `"Resume from HANDOFF.md: <objective>"`
