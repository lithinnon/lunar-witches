# ADR 0008: Secrets Management & The World-Readable `/nix/store` Boundary

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Security & Secret Isolation  

---

## 1. Context & Problem

On NixOS, any string declared inside `.nix` files (such as environment variables or passwords) is serialized into plain text derivations in `/nix/store/`. The `/nix/store/` is world-readable (`chmod -R a+r`). Any unprivileged local user, process, or compromised script can read secrets stored in Nix expressions. Furthermore, committing secrets to Git history causes irreversible leakage when repos are pushed to remotes.

## 2. Decision

We established a strict **out-of-tree secrets boundary**:
1. **No Secrets in Nix Expressions:** API tokens (`HF_TOKEN`, OpenAI keys) and enterprise passwords are strictly prohibited from all `.nix` files.
2. **Local Environment Files:**
   - Shell tokens are stored in `~/.config/secrets.env` (`chmod 600`).
   - Network credentials (e.g. campus Wi-Fi) are stored in `~/.config/chula/environment` (`chmod 600`).
   - Both files use plain `KEY=VALUE` format without `export ` prefixes, ensuring compatibility with systemd `EnvironmentFile=`.
3. **Declarative Sourcing:**
   - Sourced conditionally in shell startup:
     - Fish: `test -f "$HOME/.config/secrets.env"; and source "$HOME/.config/secrets.env"` in `programs.fish.shellInit`.
     - Bash: `[ -f "$HOME/.config/secrets.env" ] && source "$HOME/.config/secrets.env"` in `programs.bash.initExtra`.

## 3. Consequences

- World-readable store paths contain zero sensitive credentials.
- Git repositories can be safely published without risk of token leakage.
- Clear migration path towards `sops-nix` or `agenix` if daemon-level encryption is required in the future.
