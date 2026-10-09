# ADR 0003: Native Applications over Flatpak & Dynamic Binary Compatibility via `nix-ld`

> **Status:** Accepted  
> **Date:** 2026-09-30  
> **Scope:** Desktop Applications & Toolchains  

---

## 1. Context & Problem

NixOS systems lack standard FHS paths (`/lib64/ld-linux-x86-64.so.2`, `/usr/lib64`). Standard third-party binary toolchains (VS Code language servers, prebuilt Node/Python wheels, proprietary binaries, compiler backends) fail to execute with `No such file or directory`. 

Additionally, relying heavily on Flatpak introduces sandbox overhead, duplicated runtime libraries, and IPC friction with local devshells and desktop D-Bus services.

## 2. Decision

1. **Native Packaging Priority:**
   - Essential desktop applications (Brave, Digital, KeePassXC, Bottles, ProtonPlus, Telegram, LocalSend, Zoom, Equibop) are packaged natively in NixOS/Home Manager.
   - Flatpak is restricted solely to isolated browsers (Waterfox).
2. **Dynamic Binary Compatibility via `nix-ld`:**
   - Configured `programs.nix-ld.enable = true` in `modules/core/default.nix`.
   - Exposed comprehensive shared libraries (glib, gtk3, mesa, systemd, alsa, NSS, etc.) and dynamically injected ROCm runtime libraries.
   - Allows unpatched binaries, prebuilt wheels, and dynamically linked tools to run without manual `patchelf` or container layers.
3. **Google Antigravity Integration:**
   - Built natively via `inputs.antigravity-nix`:
     - `google-antigravity`: Desktop orchestrator with full Wayland, Electron, and hardware acceleration support.
     - `google-antigravity-cli` (`agy`): Native CLI binary patched for NixOS.

## 3. Consequences

- No container layer overhead (Podman/Docker/Distrobox eliminated).
- Dynamic binaries and prebuilt language servers work out-of-the-box in all developer shells.
