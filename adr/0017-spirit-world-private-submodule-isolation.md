# ADR 0017: Spirit World Private Submodule Isolation & Graceful Fallback

> **Status:** Accepted  
> **Date:** 2026-11-01  
> **Scope:** Privacy Boundaries, Secrets Management & Modular Decoupling  

---

## 1. Context & Problem

A declarative operating system configuration inevitably intersects with sensitive artifacts:
1. **API Keys & Secrets:** Tokens for Hugging Face, Brave Search, and cloud APIs.
2. **Personal Infrastructure:** Private internal IP addresses, non-public SSH configurations, and university 802.1x network credentials.
3. **Proprietary / In-Tree Packages:** Custom software packages and personal tools.

While `sops-nix` encrypts secrets at rest via Age, storing ciphertext, internal network topologies, or private package derivations directly inside the public `lunar-witches` repository creates several risks:
- Encrypted ciphertext blocks remain permanently in Git history, exposing metadata (token lengths, recipient keys, rotation frequency) and creating long-term cryptographic exposure.
- Personal network details (internal IPs, machine names) leak infrastructure topologies to public observers.
- Outsiders cloning or evaluating the configuration encounter missing keys, broken environment files, or unresolvable dependencies.

---

## 2. Decision

We established a **two-plane architecture** using a private companion Git submodule named `spirit-world` (`lithinnon/spirit-world`):

1. **Strict Repository Separation:**
   - Public `lunar-witches` contains 100% public, secret-free NixOS modules, suites, hardware traits, and open-source in-tree packages.
   - Private `spirit-world` contains all `sops-nix` encrypted files, `.sops.yaml`, personal SSH aliases, campus Wi-Fi credentials, and private in-tree package derivations.

2. **Conditional Manifestation Contract:**
   - In `hosts/lunar-qualia/default.nix`, `spirit-world` is dynamically imported if and only if the submodule exists:
     ```nix
     (if (builtins.pathExists ../../spirit-world/default.nix) then ../../spirit-world/default.nix else {})
     ```
   - When present, `spirit-world/default.nix` injects overlays (`nixpkgs.overlays`), user packages (`home-manager.users.nnon.home.packages`), and secrets (`sops.secrets`).

3. **Flake Submodule Inclusion:**
   - `flake.nix` declares `inputs.self.submodules = true;`, ensuring Nix flakes recursively package the submodule during evaluation without requiring `--impure`.

4. **Graceful Public Fallback:**
   - All modules in `lunar-witches` degrade gracefully when `spirit-world` is absent:
     - Features requiring credentials (e.g., campus Wi-Fi) default to `enable = false`.
     - Services consuming secrets (e.g., Open WebUI) check for `config.sops.templates` before attempting to load environment files.

---

## 3. Consequences

- **Public-Ready:** `lunar-witches` can be published, audited, and built by third parties without evaluation errors, broken assertions, or credential leaks.
- **Zero In-Tree Secrets:** All tokens and private network infrastructure are isolated in a separate, encrypted, access-controlled repository.
- **Clean Synchronization Protocol:** Changes to private overlays or secrets are committed and pushed within `spirit-world` before advancing the submodule pointer in `lunar-witches`.
