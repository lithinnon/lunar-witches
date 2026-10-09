# ADR 0007: Multi-User Privilege Boundaries & Git `safe.directory`

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Git Configuration & Privilege Boundaries  

---

## 1. Context & Problem

Git security patch CVE-2022-24765 enforces strict repository ownership verification: Git refuses to operate on a repository if the executing process UID does not match the file owner UID.

On NixOS, system evaluation and activation commands (`sudo -A nh os switch` or `nixos-rebuild`) execute as `root` (UID 0), while the flake repository at `/home/nnon/lunar-witches` is owned by user `nnon` (UID 1000). Without explicit configuration, Git aborts with:
```text
fatal: detected dubious ownership in repository at '/home/nnon/lunar-witches'
```

## 2. Decision

We declaratively configured `safe.directory = "*"` in `programs.git.extraConfig` within the user development profile (`modules/users/nnon/development.nix`).

## 3. Consequences

- System switch operations, automated scripts, and subshells operating with elevated privileges can read the flake Git metadata seamlessly.
- Eliminates manual ownership hacks (`chown root`) that would corrupt user ownership.
