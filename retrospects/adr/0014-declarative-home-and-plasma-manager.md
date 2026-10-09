# ADR 0014: Declarative User Environment & KDE Plasma Management via `plasma-manager`

> **Status:** Accepted  
> **Date:** 2026-10-06  
> **Scope:** User Profile, Desktop UI & Keybindings  

---

## 1. Context & Problem

KDE Plasma traditionally stores its desktop configuration, window manager shortcuts, and input profiles in mutable files inside `~/.config/` (`kwinrc`, `kglobalshortcutsrc`, `kcminputrc`). This makes desktop configurations vulnerable to state drift, manual editing regressions, and loss during system reinstalls.

Additionally, a monolithic user manifest (`users/nnon.nix`) quickly becomes bloated when mixing shell configurations, VS Code extensions, desktop MIME types, and hardware input profiles.

## 2. Decision

1. **Modularization of User Profile (`modules/users/nnon/`):**
   Decomposed into decoupled domain modules:
   - `default.nix`: System user account and Home Manager composition.
   - `shell.nix`: Fish, Bash, aliases, session variables, Btop, Fastfetch.
   - `development.nix`: VS Code profiles, Git auto-signing, GPG agent, SSH client aliases.
   - `desktop.nix`: XDG user directories, MIME applications, Service Deck, Digital circuit simulator options.
   - `plasma.nix`: Declarative KDE Plasma configuration.
2. **Adoption of `plasma-manager`:**
   - Integrated `github:nix-community/plasma-manager`.
   - Declaratively manages keyboard repeat rates, virtual desktops, global shortcuts, and input device acceleration (Keychron M6, Razer DeathAdder, Asus touchpad).
3. **PowerDevil State Management:**
   - PowerDevil AC/battery synchronization scripts use `configFile."powerdevilrc"` rather than static symlinks, allowing PowerDevil to retain runtime session state without permission collisions.

## 3. Consequences

- Desktop ergonomics, keybindings, and hardware input curves reproduce deterministically on any machine.
- User manifest is cleanly partitioned by responsibility.
