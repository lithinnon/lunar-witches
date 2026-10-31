# Historical Session Ledger Archive (October 2026)

> **Context:** This archive captures completed technical milestones, packaging efforts, and hardware proofs graduated from [`HANDOFF.md`](../../HANDOFF.md) to keep the active working register compact.  
> For deep thematic extraction, root cause analyses, and architectural narratives mined from these sessions, consult [`2026-10-session-chronicles.md`](../../retrospects/history/2026-10-session-chronicles.md).

---

## 1. Session Lineage

| Date Range | Primary Agents | Model / Harness | Indexed Knowledge & Chronicles | Cold Transcript Path |
| :--- | :--- | :--- | :--- | :--- |
| **2026-10-05 – 2026-10-09** | Pi | Kimi K2.6 / MiMo | [`2026-10-session-chronicles.md`](../../retrospects/history/2026-10-session-chronicles.md) | `~/.config/pi/agent/sessions/--home-nnon-lunar-witches--/2026-10-05T05-18-09-818Z_01a10a7f-7d9a-753c-9b68-372aa214bb10.jsonl` |
| **2026-09-30 – 2026-10-10** | Antigravity | Google Antigravity | [`2026-10-session-chronicles.md`](../../retrospects/history/2026-10-session-chronicles.md) | `~/.gemini/antigravity-cli/brain/f73d4a6a-84c7-4614-9114-d72055951b42/.system_generated/logs/transcript.jsonl` |
| **2026-10-11 – 2026-10-13** | Antigravity | Google Antigravity | [`2026-10-session-chronicles.md`](../../retrospects/history/2026-10-session-chronicles.md) | `~/.gemini/antigravity-cli/brain/463892eb-7168-495e-bac8-3611a3078d13/.system_generated/logs/transcript.jsonl` |
| **2026-10-13** | Pi | MiMo v2.6 | [`2026-10-session-chronicles.md`](../../retrospects/history/2026-10-session-chronicles.md) | `~/.config/pi/agent/sessions/--home-nnon-lunar-witches--/2026-10-13T07-21-01-325Z_01a13422-d88c-70d1-a404-d738cde6a7e2.jsonl` |

---

## 2. Completed Milestones by Pi (MiMo / K2.6)

1. **Added `llama-swap` to Prose Suite (`647c5a4`):** Packaged `llama-swap` alongside `llama-cpp-vulkan` in `modules/suites/ai/prose.nix`.
2. **Configured XDG Skeleton & Boulesis Model (`c3f42ef`, `77dccde`):** Declared `creative/boulesis-v2.1-headtune` with `ttl=1200s`, Vulkan0 compute device, and DeepSeek reasoning flags.
3. **User Service & AI Service Deck (`a0f5759`):** Wired `llama-swap.service` into user systemd units and registered it on the AI Service Deck group.
4. **Refactored Config to Typed Nix (`9fefc91`):** Converted raw text YAML into `pkgs.formats.yaml` generated from typed Nix attributes.

---

## 3. Completed Milestones by Antigravity

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
7. **Decommissioned Legacy `rocmctl` Tooling:**
   - Deleted the obsolete Fedora-era binary `/home/nnon/.local/bin/rocmctl` and purged the legacy skill directory at `~/.gemini/config/skills/rocmctl`.
8. **Refactored `suite-ai-rocm` to 3-Tier Best Practice (`modules/suites/ai/rocm.nix`):**
   - Replaced full compiler package on global `$PATH` with lightweight `rocm-diagnostics` wrapper exposing only `rocminfo`, `amd-smi`, and `rocm_agent_enumerator`.
   - Stripped global `ROCM_PATH`, `HIP_PATH`, and `CMAKE_PREFIX_PATH` session variables to eliminate pollution of unrelated CMake/host builds.
   - Retained dynamic library resolution in `programs.nix-ld.libraries` for standalone binaries.
   - Kept full compiler suite, include paths, and Python AI venv automation strictly within `devShells` (`amd-ai-dev`).
   - Removed `exposeCompilers` toggle entirely to enforce strict isolation of compilers to devshells.
9. **Decoupled Flake DevShells to `shells/` Aggregator (`shells/rocm.nix`, `shells/loom.nix`, `flake.nix`):**
   - Created top-level `shells/default.nix` aggregator imported directly into `flake.nix`, maintaining clear domain boundaries.
10. **Integrated Build Caching (`shells/rocm.nix`):**
    - Packaged `ccache` and `sccache` into `amd-ai-dev` developer shell.
    - Exported standard CMake compiler launchers `CMAKE_C_COMPILER_LAUNCHER`, `CMAKE_CXX_COMPILER_LAUNCHER`, and `CMAKE_HIP_COMPILER_LAUNCHER`.
11. **Resolved Linux Kernel 6.18+ / 7.2 AMDXDNA Ring Buffer Allocation Bug (`retrospects/postmortems/2026-10-09-amdxdna-ring-buffer-eagain.md`):**
    - Identified upstream kernel driver bug in `amdxdna_ring_create()` returning `err=-11 (EAGAIN)` caused by missing locked memory limits (`RLIMIT_MEMLOCK`).
    - Configured unlimited `memlock` in `modules/core/default.nix` across `security.pam.loginLimits` and `systemd.extraConfig = "DefaultLimitMEMLOCK=infinity"`.
12. **In-Tree Packaging of `xrt-amdxdna` (`pkgs/xrt-amdxdna`):**
    - Built and packaged matched XRT 2.21.75 userspace plugin from official AMD XDNA source, enabling Python `pyxrt` bindings and XRT tools.
13. **Empirical Physical Silicon Verification of AMD XDNA 2 AIE2p NPU (`retrospects/proofs/2026-10-09-amd-xdna-iron-xrt-verification.md`):**
    - Executed live MLIR-AIE and IRON JIT compilation on physical NPU hardware (`/dev/accel/accel0`).
    - Allocated shared host-device buffers via XRT BO, loaded compiled `.xclbin` onto 4 AIE cores, and verified bit-exact tensor outputs.
14. **Empirical Silicon Verification of ROCm Loom (`libamdf`) (`retrospects/proofs/2026-10-09-rocm-loom-libamdf-silicon-execution.md`):**
    - Compiled and executed Loom kernels targeting both physical GPU (`gfx1151`) and physical NPU (`aie2p`) silicon via Linux DRM (`/dev/accel/accel0`).
    - Proved zero-XRT direct hardware execution.
15. **Authored Master Living Architecture Manual (`retrospects/manuals/amd-ai-compute-stack.md`):**
    - Synthesized complete end-to-end documentation covering kernel modules, CachyOS BORE tuning, devshells, TheRock packaging, and XDNA NPU compilation.
16. **Categorized Repository Retrospects (`retrospects/`):**
    - Restructured documentation into 6 clear domains: `adr/`, `postmortems/`, `proofs/`, `manuals/`, `troubleshooting/`, and `history/`.
17. **Multi-Method ROCm Loom Shell (`shells/loom.nix`):**
    - Added support for all three compilation and execution methods:
      1. `hrx-run`: LD_PRELOAD runtime shim for standard ROCm binaries on HRX.
      2. `hrxcc`: Clang-based compiler wrapper producing native HRX binaries.
      3. `loom-compile`: Pure Loom direct-to-metal AIE compiler.
18. **Empirical Verification of PyTorch & Flash Attention on HRX (`retrospects/proofs/2026-10-09-pytorch-flash-attention-live-hrx-execution.md`):**
    - Proved Flash Attention 2 forward passes execute bit-exactly on HRX in `bfloat16`.
19. **Cleaned `loom-dev` DevShell:**
    - Extended `shells/loom.nix` with PyTorch and Flash Attention 2 while strictly excluding XRT to preserve Loom's direct Linux DRM architecture.
20. **Parameterized `shells/loom.nix` (`mkLoomDevShells` / `mkLoomDevShell`):**
    - Abstracted devshell creation across GPU architectures and exported functions in `flake.lib`.
21. **Flake Updates & Optimization:**
    - Updated `flake.lock` (nixpkgs `e7439b6`, home-manager `dfadbe5`).
    - Purged KDE PIM / Akonadi overhead from `modules/suites/desktop/plasma.nix`, shedding 962 MiB of closure.
22. **In-Tree Packaging of `beellama.cpp` (`pkgs/beellama`):**
    - Replaced Nixpkgs `llama-cpp-vulkan` with in-tree `beellama.cpp`, cutting 87.3 MiB.
    - Updated `llama-swap.yml` Boulesis runner to native ROCm HIP graphs, flash attention, and reasoning flags.
23. **Created Dedicated `suite-ai-local` (`modules/suites/ai/local.nix`):**
    - Decoupled local inference binaries from `suite-ai-prose`.
    - Composed into `hosts/lunar-qualia/default.nix`.
24. **Configured 64k `snc8` Disk-Cached Model in `llama-swap` (`modules/suites/ai/prose.nix`):**
    - 64k context (`--ctx-size 65536`).
    - Non-linear 8-bit sub-normalized cache quantization (`--cache-type-k snc8 --cache-type-v snc8`).
    - 1024 `bf16` tail tokens preserving entire Sliding Window Attention (SWA).
    - True 0-RAM overhead with 16 GiB NVMe Radix disk cache (`--cache-ram 0 --cache-disk 16384`).
25. **Switched `beellama.cpp` to Native Standard ROCm HIP (`pkgs/beellama`, `modules/suites/ai/local.nix`):**
    - Compiled `beellama.cpp` via `build.sh` into `build/` linked directly to TheRock 10.1 HIP (`libamdhip64.so.7`) and `hipBLAS`.
    - Parameterized `pkgs/beellama` with `backend ? "rocm"`.
    - Added `suites.ai.local.backend` and `suites.ai.local.package` options.
26. **Enabled Wire Tooltips in Digital (`modules/users/nnon/desktop.nix`):**
    - Declared `<entry><string>wireToolTips</string><boolean>true</boolean></entry>` in `home.file.".digital.cfg"`.
    - Solved read-only nix store symlink limitation in Home Manager.

---

## 4. Recently Graduated from `HANDOFF.md` (Window Rotation 2026-10-13)

> HANDOFF sliding-window items 29–30 rotated out by Pi (MiMo v2.6); deep detail already captured in items 23–25 above.

27. **Boulesis Local-Inference Stack (HANDOFF items 29–30; see 23–25 in depth):**
    - Decoupled `beellama` into `modules/suites/ai/local.nix` (`suite-ai-local`).
    - Boulesis 26B A4B in `llama-swap`: 64k context, `snc8`/`snc8` KV cache, 1024 `bf16` tail tokens, 0-RAM with 16 GiB NVMe radix disk tier.
    - Switched `beellama.cpp` to native standard ROCm HIP (`backend ? "rocm"` in `pkgs/beellama`, `suites.ai.local.backend`).
28. **Declared GitHub CLI `programs.gh` (`modules/users/nnon/development.nix`):**
    - Configured `programs.gh` with `git_protocol: "ssh"`, fish completions, and git credential helper integration.
    - Activated Generation 117.
29. **Declared `agentic/lfm2.5-24b-a2b` in `llama-swap` (`7f8a92e`, `modules/suites/ai/prose.nix`):**
    - Configured Liquid AI LFM2.5-24B-A2B QAD-Q4_0 checkpoint with 131k context (`--ctx-size 131072`), `snc4/snc4` KV cache quantization, 1024 `bf16` tail tokens, 16 GiB persistent NVMe radix tier, Flash Attention, Jinja chat templating (`--jinja`), and DeepSeek-format reasoning extraction.
    - Activated Generation 124; verified via `curl http://127.0.0.1:8080/v1/models`.
30. **Tuned `agentic/lfm2.5-24b-a2b` Configuration (`bde5133`, `modules/suites/ai/prose.nix`):**
    - Set 10-minute TTL (`ttl = 600`), enabled reasoning preservation (`--reasoning-preserve`), and adjusted exact KV tail to 256 tokens (`--kv-tail-tokens 256`).
    - Activated Generation 125.
31. **Automated Pi Extension & Model Updates on Activation (`c4ea763`, `modules/suites/ai/pi-coding-agent.nix`):**
    - Hooked `home.activation.updatePi` DAG hook to run `pi update --models` and `pi update --extensions`.
32. **Added Foliate EPUB Reader & MIME Associations (`72c702c`, `modules/suites/desktop/apps.nix`):**
    - Declared Foliate and registered `application/epub+zip` MIME associations.
33. **Migrated from Compromised `nix-cachyos-kernel` to Chaotic-Nyx (`b840914`):**
    - Replaced `xddxdd/nix-cachyos-kernel` with `chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"`.
    - Purged dead Attic server and trusted `nyx-cache.chaotic.cx` + `@wheel` in `modules/core/default.nix`.
    - Activated Generation 130.
34. **Adopted Zen 4 Clang ThinLTO CachyOS Kernel (`pkgs.linuxPackages_cachyos-lto-znver4`, `b236829`):**
    - Switched `boot.kernelPackages` to `pkgs.linuxPackages_cachyos-lto-znver4` for Strix Halo silicon instruction tuning.
    - Verified instantaneous cache downloads from `nyx-cache.chaotic.cx`; activated Generation 131.
35. **Resolved Flatpak CJK Font Rendering & Dangling Symlinks (`9a74358`, `bd99dc0`):**
    - Provisioned `/var/lib/flatpak/overrides/global` via `systemd.tmpfiles.rules` (`modules/suites/desktop/apps.nix`) granting `/nix/store:ro`.
    - Defined explicit CJK fallback prioritization (`fonts.fontconfig.defaultFonts`) in `modules/suites/desktop/fonts.nix`; activated Generation 132.
48. **Purged Obsolete `--cache-reuse` Flag from `llama-swap` Runner (`2b02c5f`, `modules/suites/ai/local.nix`):**
    - Removed obsolete `--cache-reuse 256` flag following `beellama.cpp` argument parser refactor (`7db0738a`); activated Generation 135.
51. **Integrated `sops-nix` Declarative Secret Management (`2d43b1f`, `a64afa9`, `c0dfcc1`):**
    - Introduced `self.nixosModules.feature-sops` trait in `modules/features/sops.nix`, using host SSH ed25519 key (`/etc/ssh/ssh_host_ed25519_key`) converted to age via `ssh-to-age`.
    - Configured `.sops.yaml` with dual age recipients (`admin_nnon`, `admin_ssh`, and `host_lunar_qualia`).
    - Created `secrets/secrets.yaml` with encrypted `hf_token`, decrypted to `/run/secrets/hf_token` (`0400` owned by `nnon`).
    - Purged unmanaged `~/.config/secrets.env` logic from `fish.shellInit` and `bash.initExtra` in `modules/users/nnon/shell.nix`, migrating shells to read `/run/secrets/hf_token`; activated Generation 137.
52. **Migrated SillyTavern to User-Level Service and `~/.local/share/SillyTavern` (`236a884`, `modules/suites/ai/prose.nix`, `modules/users/nnon/desktop.nix`):**
    - Migrated existing 66MB state from `/var/lib/SillyTavern` to `${XDG_DATA_HOME}/SillyTavern` (`~/.local/share/SillyTavern`), setting clean `nnon:users` ownership.
    - Preserved legacy state at `/var/lib/SillyTavern.bak`.
    - Refactored `suite-ai-prose` to disable system `services.sillytavern` and provision `systemd.user.services.sillytavern` via Home Manager.
    - Linked declarative drift-checked `config.yaml` to `~/.local/share/SillyTavern/config.yaml` via `xdg.dataFile`.
    - Updated Service Deck Plasma widget to control SillyTavern under `scope = "user"`, enabling zero-privilege toggling; activated Generation 138.
53. **Tuned Boulesis KV Cache Quantization & 96k Context Window (`fd7a0e1`, `6725e28`, `modules/suites/ai/local.nix`):**
    - Configured asymmetric SNC quantization (`cacheTypeK = "snc4"`, `cacheTypeV = "snc8"`) with 1024 `bf16` tail tokens.
    - Expanded context window from 64k to 96k (`ctxSize = 98304`, ~72,000 words); activated Generation 141.
54. **Renamed `beellama.cpp` to `triellama.cpp` & Added Vector Embedding Model (`pkgs/triellama`, `modules/suites/ai/local.nix`):**
    - Renamed in-tree derivation `pkgs/beellama` to `pkgs/triellama`, maintaining backward-compatible alias.
    - Configured `vector/embeddinggemma-2` in `llama-swap`; activated Generation 146.
55. **Configured `llama-swap` Groups & CPU Offloading for Embeddings (`07542e8`, `modules/suites/ai/local.nix`):**
    - Declared `groups` in `llama-swap`: `chat` (GPU pool) and `embeddings` (CPU pool).
    - Offloaded `vector/embeddinggemma-2` to 12 CPU threads; activated Generation 148.
56. **Allocated 1024 MiB RAM Cache Specifically to Boulesis (`modules/suites/ai/local.nix`):**
    - Parameterized `cacheRam ? null` in `mkServerCmd`; added `-cram 1024` to Boulesis in `extraFlags`.
    - Switched and activated Generation 150; validated `llama-swap.service`.
57. **Integrated Hugging Face `git-xet`, Git LFS & Pinned RDTS Patchelf (`fe878ff`, `modules/users/nnon/development.nix`, `pkgs/radeon-developer-tool-suite/default.nix`):**
    - Declared `programs.git.lfs.enable = true` and `lfs."customtransfer.xet"` agent in Home Manager.
    - Added `pkgs.git-xet` to `home.packages`.
    - Fixed RDTS build failure under nixpkgs `patchelf 0.19.2` by pinning `patchelf 0.15.2` in `nativeBuildInputs`.
    - Switched and activated Generation 153.
58. **Purged Goverlay, Added `npm:pi-subagents`, Updated Flake Inputs & Fixed `mcp-nixos` (`312d52b`, `modules/suites/ai/pi-coding-agent.nix`, `pkgs/default.nix`, `flake.lock`):**
    - Removed `goverlay` and purged runtime directories (`~/.config/{goverlay,Goverlay,MangoHud,vkBasalt,vkSumi}`, `afmf-linux` implicit layer and libs).
    - Added `"npm:pi-subagents"` package to Pi coding agent suite.
    - Updated all flake inputs via `nix flake update`.
    - Overrode `fastmcp-slim` with `mcp = pyFinal.mcp_1` (1.29.0) in `pkgs/default.nix` to fix `mcp-nixos` evaluation with upstream nixpkgs 26.11 bumping `mcp` to 2.x; activated Generation 156.
59. **Conformed Shell & Toolchains to XDG Base Directory Specification (`modules/core/default.nix`, `modules/users/nnon/default.nix`, `modules/users/nnon/shell.nix`):**
    - Configured system-level `nix.settings.use-xdg-base-directories = true;` to place Nix channels and defexpr under `$XDG_STATE_HOME`.
    - Configured user-level `xdg.enable = true;`, standard XDG session variables (`CARGO_HOME`, `DOTNET_CLI_HOME`, `CODEX_HOME`, `TRITON_HOME`, `PYTHON_HISTORY`, `GTK2_RC_FILES`, `NPM_CONFIG_*`, `_JAVA_OPTIONS`), `sessionPath`, and `wget` alias.
    - Migrated existing home dotfiles into their corresponding XDG destinations (including Digital circuit preferences to `~/.config/java/.userPrefs`).
    - Provisioned declarative `xdg.configFile."xdg-ninja/ignore"` suppressing brittle/high-risk items (`.gnupg`, `.pulse-cookie`, `.zoom`) while keeping upstream-hardcoded Category C candidates visible.
60. **Integrated Typst Toolchain & VS Code Extension (`f9d6876`, `modules/suites/development/default.nix`, `modules/users/nnon/development.nix`):**
    - Added `typst` (0.15.1), `tinymist` (0.15.10 LSP), and `typstyle` (0.15.2 code formatter) to `suite-development`.
    - Added `vscode-extensions.myriad-dreamin.tinymist` to user VS Code profile.
    - Switched and activated Generation 158; verified PDF compilation.
61. **Configured `reasoning/qwen3.8-26b-a4b` & Purged LFM 24B in `llama-swap` (`modules/suites/ai/local.nix`):**
    - Parameterized `mkServerCmd` for local weights (`model`), multimodal projectors (`mmproj`), Jinja chat templates (`chatTemplate`), and safe radix cache limits.
    - Declared `reasoning/qwen3.8-26b-a4b` with 128k context, symmetric `snc4` KV cache, 512 `bf16` tail tokens, and `--spec-type draft-mtp`.
    - Removed `agentic/lfm2.5-24b-a2b` from models and `groups.chat.members`; switched to Generation 161.
62. **Switch Qwen KV Cache to Asymmetric SNC8 Value (`a512b6a`, `modules/suites/ai/local.nix`):**
    - Switched `cache_type_v` to `snc8` while keeping `cache_type_k` as `snc4` for higher numerical stability and fidelity.
    - Switched and activated Generation 164.
63. **Updated Qwen3.8-26B-A4B Model & Template Paths (`a587d4c`, `modules/suites/ai/local.nix`):**
    - Updated model path from `qwen-3.8-26b-moe` to `qwen3.8-26b-a4b` directory.
    - Updated chatTemplate path similarly for Jinja templates.
    - Committed with `feat(ai): update qwen3.8-26b-a4b model and template paths`.
64. **Configured Pi Thinking Level (`high`), System Invariants & Agent Guard (`modules/suites/ai/pi-coding-agent.nix`):**
    - Set `defaultThinkingLevel = "high"`, which maps directly to `xhigh` in upstream froggeric v22.5 chat template.
    - Added `appendSystem` cognitive invariants (domain boundaries, targeted CLI probing, anti-looping).
    - Provisioned `loop-breaker.ts` extension with tool-call cycle detection, output truncation (>100 lines/6KB), and empty-search annotation.

65. **Fully Migrated from Pi to OpenCode Suite (`suite-ai-opencode`):**
    - Created `modules/suites/ai/opencode.nix` with declarative `opencode.json` (pointing to `llama-swap` provider, `reasoning/qwen3.8-26b-a4b`, native MCP `nixos`, websearch/fetch, and `AGENTS.md` instructions).
    - Configured `username = "nnon"`, `snapshots = true`, `formatter = true`, and SOPS `brave_api_key` integration for MCP Brave search.
    - Removed `modules/suites/ai/pi-coding-agent.nix` and switched host leaf `lunar-qualia` composition.
    - Updated shell aliases in `modules/users/nnon/shell.nix` (`nix-agent-opencode` / `nix-agent`).
66. **OpenCode Aider-Style Fuzzy Replacer, Typo Tolerance & Cognitive Guard Suite (`4da6590`, `modules/suites/ai/opencode.nix`, `AGENTS.md`):**
    - Implemented OpenCode plugin `${config.xdg.configHome}/opencode/plugins/fuzzy-edit/index.js` with 4 multi-guard protections:
      1. Pass 1 line-trimmed matching (ignoring indentation discrepancies) and relative indentation repair.
      2. Pass 2 Levenshtein distance typo matching (up to 15% length tolerance to catch perceptual slips like `sites` vs `suites`) and anchor line repair.
      3. Anti-`sed` guard blocking raw `sed -i` line-arithmetic modifications on source files.
      4. Negative-proof annotator in `tool.execute.after` to halt infinite search loops on 0 matches, and silent failure annotator for non-zero exit codes.
    - Documented Full-Graph Dependency Convergence Invariant and Cognitive Guardrails in `AGENTS.md`.

70. **Anti-Looping Architecture: DRY Sampling, Loop Guard & Intermediate Reasoning Stripping (`cb6d703`):**
    - Diagnosed empirical root cause of multi-turn looping in `qwen3.8-26b-a4b`: intermediate `<think>` blocks kept in KV cache acted as autoregressive attractor traps.
    - Generalized `mkServerCmd` in `local.nix` with typed options and universal defaults (`reasoningBudget = 4096`, `reasoningLoopGuard = "force-close"`).

71. **Master Directives, Syntax-Safe Sampling & Unified Prompt Alignment (`cd739f2`, `c1f7215`, `c71231b`):**
    - Set `tool_call_format = 'json'` in `chat_template.jinja` (`9fbd8e7`), fixing corrupted XML parameter parsing in `llama-server`.
    - Tuned `dryAllowedLength = 5`, `drySequenceBreaker = "none"`, and `repeatPenalty = 1.02` in `local.nix`.
    - Consolidated agent instructions into `~/.agents/models/Qwen3.8-26B-A4B.md` and deleted `modules/suites/ai/opencode/instructions.md`.

72. **Claude Desktop, Open WebUI Suite & Gemma 4 26B Heretic Integration (`348c070`):**
    - Added `suite-ai-claude` (`modules/suites/ai/claude.nix`) wrapping `claude-desktop-fhs` and `claude-code`.
    - Added `suite-ai-open-webui` (`modules/suites/ai/open-webui.nix`) with custom Python overlay pinning `mcp = 1.30.0`.
    - Upgraded `local.nix` with configurable `batchSize`/`ubatchSize` and swapped in `unleashed/gemma-4-26B-A4B-it` (Uncensored Heretic Q4_K_S).
    - Registered `open-webui.service` in Service Deck desktop configuration.
73. **KScreen/Baloo Crash Fixes, GPU Boost Query Decoupling & r2modman (`bd107f7`, `969290b`):**
    - Decoupled `amdgpu-boost` metrics queries (`json`/`status`) from display rate switching, stopping 1000ms `kscreen-doctor` storms.
    - Bound `amdgpu-boost.service` to `graphical-session.target` and guarded all `kscreen-doctor` calls with active display checks.
    - Declaratively provisioned `QT_QPA_PLATFORM=offscreen` as drop-in for `kde-baloo.service` in `suite-desktop-plasma`.
    - Integrated `r2modman` into `suite-gaming` and registered `x-scheme-handler/ror2mm` in `xdg.mimeApps` for Thunderstore web installs.
74. **Google Antigravity IDE Integration (`7ea4865`):**
    - Provisioned `google-antigravity-ide` in `suite-ai-antigravity` (`modules/suites/ai/antigravity.nix`).
    - Registered `x-scheme-handler/antigravity = "antigravity-ide.desktop"` in `modules/users/nnon/desktop.nix`.
    - Verified generation 196 activation and default MIME association.
75. **Declarative Plasma KSycoca Refresh Hook & Search Verification (`3861386`, Generation 197):**
    - Added `home.activation.kbuildsycoca` in `modules/users/nnon/plasma.nix` ensuring every `nh os switch` immediately rebuilds the KSycoca application index with proper locale and `XDG_MENU_PREFIX=plasma-`.
    - Documented NixOS symlink inotify limitation and Kickoff zero-restart re-instantiation trick in `retrospects/troubleshooting/nixos-desktop-quirks.md#14`.
    - Empirically verified Kickoff search and KRunner (`Alt+Space`) resolving `antigravity-ide` and `r2modman`.
76. **Antigravity IDE User Settings Port & Loom Rust Integration (`5979388`):**
    - Ported settings to `~/.antigravity-ide/User/` and added Rust toolchain to `shells/loom.nix`.
77. **Documentation Debloat & Relative Link Canonicalization (`8c41446`):**
    - Removed `file://` absolute URIs and debloated `README.md`, `AGENTS.md`, and `HANDOFF.md`.
78. **Extract Shared ROCm Foundation to `shells/common-rocm.nix` (`c5e7031`):**
    - Created `mkCommonRocm` unifying constraints, Flash Attention builder, virtualenv bootstrapper, compiler caching, package lists, and library paths. Refactored `shells/rocm.nix` and `shells/loom.nix`.
79. **Declarative Loom SDK v0.1.0 Packaging & Integration (`50ffc8c`):**
    - Created `pkgs/hrx-loom` with patchelfed `loom-compile`, `loom-serve`, `libloomc`, `libiree`, and Python site-packages. Added to `loom-dev` shell without manual CMake build requirements.
80. **Reorganize AMD Shells & Extract Scripts (`453e3a0`):**
    - Moved shells to `shells/amd/` (`common.nix`, `standard.nix`, `loom.nix`, `default.nix`) and extracted embedded shell scripts into `shells/amd/scripts.nix`.
81. **Canonicalize AMD Shell Names (`2a77efd`):**
    - Renamed primary/runtime devShells to `standard-dev`/`standard` and `loom-dev`/`loom` while maintaining backward-compatible aliases (`amd-ai-dev`, `hip-runtime`, `loom-runtime`).
82. **Unify AMD DevShells into `amd-dev` & `amd-runtime` (`be04c99`):**
    - Replaced `standard.nix` and `loom.nix` with `dev.nix` (`amd-dev`) and `runtime.nix` (`amd-runtime`), unifying the entire ROCm, PyTorch, Flash Attention, XRT, Loom, HRX, and Rust toolchain into a single studio.
83. **Declarative HRX Runtime Package & Imperative Dir Purge (`a8a818e`):**
    - Created `pkgs/hrx-runtime/default.nix` packaging `libhrx`, `libamdf`, `libamdhip64.so`, and `amdf-enumerate` with autoPatchelfHook.
    - Wired `pkgs.hrx-runtime` into `shells/amd/dev.nix`, `shells/amd/runtime.nix`, and `shells/amd/scripts.nix`.
    - Permanently purged imperative `~/.local/share/rocm/hrx-system` from disk.
84. **Unified `init-venv` & Decoupled Package Caching (`0e4c0a5`):**
    - Consolidated `init-rocm-venv`, `build-flash-attention`, and `init-iron-venv` into canonical `init-venv` with `--torch`, `-fa`/`--flash-attn`, and `--iron` flags.
    - Decoupled package cache (`~/.local/share/rocm/pkg-cache-${gfx}`) from virtualenvs: `init-venv` uses Btrfs reflink copy (`--reflink=auto`) to seed 6.6GB packages into clean project-local `./.venv` in under 0.5s.
    - Removed global venv auto-activation from `common.nix` (strictly project-local `./.venv` activation).
85. **Pruned Bazel & Streamlined AMD Devshell (`2e03656`):**
    - Removed unused build tools `bazelisk` and `bazel_7` from `shells/amd/dev.nix`.
    - Removed redundant `(Active Venv: ...)` output from devshell startup banner.
86. **Refactored `pkgs/` & Enforced Repository Invariants (`HEAD`):**
    - Single-sourced in-tree package set across `perSystem.packages` and `flake.overlays.default` via `inTreePackages` map, eliminating boilerplate duplication.
    - Enforced Zero Backward-Compatibility rule: purged legacy aliases `amd-ttm`, `beellama`, `rdts`, `rgp`, `radeon-gpu-profiler`, and `loom`.
    - Refactored call sites: updated `modules/hardware/gpu/amd.nix` to canonical `pkgs.radeon-developer-tool-suite`, removed `ln -s amd-ttm` from `pkgs/mem-ttm`, updated `modules/suites/ai/rocm.nix` to call `pkgs.rocm-therock` directly, and updated `shells/amd/` to prefer `pkgs.*` with fallback.
    - Added `rocm-therock-gfx1151` to `packages` for direct CLI evaluation and build.
87. **Disable Baloo File Indexer Declaratively & Purge Database (`d776538`):**
    - Configured `programs.plasma.configFile."baloofilerc"."Basic Settings"."Indexing-Enabled" = false;` in `modules/users/nnon/plasma.nix`.
    - Removed obsolete headless `kde-baloo` systemd drop-in from `modules/suites/desktop/plasma.nix`.
    - Purged index database and stopped active indexer process (`balooctl6 purge && balooctl6 disable`).
88. **Laptop Battery Optimization & Dendritic Cleanup:**
    - Removed display refresh rate switching from `pkgs/sync-power-state/sync-power-state.sh`.
    - Re-enabled AMD Display Core Idle Power States (`disableDcIps = false;` in `hosts/lunar-qualia/default.nix`).
    - Purged `modules/hardware/network/realtek-rtw89.nix` (unblocking PCIe ASPM L1/L1ss) and set `wifi.powersave = true`.
89. **Purge Obsolete `amdgpu-boost` Daemon & Artifacts (`HEAD`):**
    - Deleted `modules/features/amdgpu-boost.nix`, `pkgs/amdgpu-boost/`, and `pkgs/plasma-widget-amdgpuboost/`.
    - Removed user background service and Service Deck references, delegating GPU power management to native AMD PMFW `auto` DPM governor.
90. **Eliminate Deprecated `stdenv.is<Os>` Evaluation Warnings (`HEAD`):**
    - Added modern `rust-overlay` input in `flake.nix` and bound `aagl.inputs.rust-overlay.follows = "rust-overlay"`.
    - Updated lockfile to pull upstream `rust-overlay` (`6ecf534`), resolving deprecated `stdenv.isLinux` and `stdenv.isDarwin` aliases.
91. **Closure Size Optimization & OpenJDK Deduplication (`HEAD`):**
    - Purged leaked build-time `env-vars` from `pkgs/rocm-therock/default.nix`, severing runtime reference to 1.90 GiB upstream source tarball.
    - Bound `digital-egro.inputs.nixpkgs.follows = "nixpkgs"` in `flake.nix`, overrode `mvnHash` in `modules/suites/desktop/apps.nix` for maven dependency convergence, and eliminated duplicate OpenJDK 21 (~568 MiB reclaimed).

