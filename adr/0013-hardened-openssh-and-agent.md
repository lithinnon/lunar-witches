# ADR 0013: Hardened OpenSSH Daemon & Passphrase-Backed SSH Agent Integration

> **Status:** Accepted  
> **Date:** 2026-10-06  
> **Scope:** Security & Remote Access  

---

## 1. Context & Problem

Exposing SSH services on a portable laptop requires strict defense-in-depth against credential spraying, brute-force attacks, and unauthenticated shell access. Meanwhile, managing encrypted Ed25519 client keys requires seamless passphrase caching without typing passwords on every git push or remote session.

## 2. Decision

1. **Inbound SSH Server (`feature-openssh`):**
   - Packaged in `modules/features/openssh.nix` with key-only authentication:
     ```nix
     PasswordAuthentication = false;
     KbdInteractiveAuthentication = false;
     PermitRootLogin = "no";
     ```
   - Authorized public keys are managed declaratively per-user in `users.users.<user>.openssh.authorizedKeys.keys`.
2. **Outbound SSH Client & Passphrase Caching:**
   - Enabled `programs.ssh.startAgent = true;` in `modules/core/default.nix` to launch a systemd user OpenSSH agent and export `SSH_AUTH_SOCK` across fish/bash shells.
   - Configured graphical passphrase caching via KDE Plasma's `ksshaskpass` (`SSH_ASKPASS` and `SSH_ASKPASS_REQUIRE = "prefer"`).
   - Integrated with KWallet to remember Ed25519 key passphrases securely across desktop logins.

## 3. Consequences

- Remote access is hardened against password brute-force attacks.
- Outbound Git operations and SSH sessions cache key passphrases securely via KDE Plasma.
