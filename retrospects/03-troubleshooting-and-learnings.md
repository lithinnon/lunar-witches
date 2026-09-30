# Retrospect 03: Troubleshooting, Edge Cases & Learnings

During the migration and post-install configuration, several notable edge cases and NixOS nuances were encountered and resolved.

---

## 1. ESP Random Seed Security Warning
- **Symptom:**
  ```text
  ⚠️ Mount point '/boot' which backs the random seed file is world accessible, which is a security hole! ⚠️
  ```
- **Cause:** Default VFAT mount options in systemd-boot allow standard world-readable permissions (0022), leaving `/boot/loader/random-seed` readable by unprivileged users.
- **Resolution:** Added `options = [ "fmask=0077" "dmask=0077" ];` to `fileSystems."/boot"` in [`hosts/lunar-qualia/hardware.nix`](file:///home/nnon/lunar-witches/hosts/lunar-qualia/hardware.nix#L18).

---

## 2. Nix Garbage Collection Evaluation Conflict
- **Symptom:**
  ```text
  evaluation warning: programs.nh.clean.enable and nix.gc.automatic are both enabled. Please use one or the other to avoid conflict.
  ```
- **Cause:** Both `programs.nh.clean` (Yet Another Nix Helper) and `nix.gc.automatic` were active simultaneously in `modules/core/default.nix`.
- **Resolution:** Removed the manual `nix.gc` block and let `programs.nh.clean` manage cache retention (`--keep-since 4d --keep 3`) uniformly.

---

## 3. Deprecated Platform System Attribute
- **Symptom:**
  ```text
  evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
  ```
- **Cause:** Packages referenced `pkgs.system` directly when selecting architecture outputs.
- **Resolution:** Updated references in `home.nix` to use `pkgs.stdenv.hostPlatform.system`.

---

## 4. Home Manager Activation File Collisions
- **Symptom:**
  ```text
  Existing file '/home/nnon/.config/fish/config.fish' ... to move the file ... Set 'home-manager.backupFileExtension = "backup"'
  unit-home-manager-nnon.service failed (code=exited, status=1/FAILURE)
  ```
- **Cause:** Restoring backup files from the external SD Card into `/home/nnon` placed pre-existing config files where Home Manager intended to create symlinks. By default, Home Manager refuses to overwrite unmanaged files.
- **Resolution:** Added `home-manager.backupFileExtension = "backup";` to the Home Manager block in [`hosts/lunar-qualia/default.nix`](file:///home/nnon/lunar-witches/hosts/lunar-qualia/default.nix#L26).

---

## 5. PATH Propagation & Fish Shell Architecture
- **Symptom:** `amd-ttm` or scripts in `~/.local/bin` were not visible in newly launched Fish shells despite `home.sessionPath` being configured.
- **Cause:** 
  1. `home.sessionPath` generates `hm-session-vars.sh` and `hm-session-vars.fish`.
  2. In graphical Wayland sessions (SDDM/Plasma), environment variables are evaluated at login. Because the desktop session booted before the new configuration was added, the running session held stale environment tables.
  3. `hm-session-vars.fish` has an idempotency guard (`if [ -n "$__HM_SESS_VARS_SOURCED" ]; return; end`). Child Fish shells inherited the flag and skipped re-sourcing.
  4. Fish treats `$PATH` as an array rather than a colon-delimited string.
- **Resolution:**
  - Configured `environment.localBinInPath = true;` in system core configuration.
  - Added `fish_add_path --path --prepend "$HOME/.local/bin"` to `programs.fish.shellInit` in `home.nix`.
  - Configured `programs.bash.initExtra` for Bash shells.

---

## 6. Legacy Standalone Binary Shadowing
- **Symptom:** `which agy` pointed to `/home/nnon/.local/bin/agy` (v1.2.13) instead of the declarative Nix package (v1.2.14).
- **Cause:** A 220 MB legacy binary and `antigravity-update-hook` remained in `~/.local/bin` from Fedora.
- **Resolution:** Removed both files; verified `which agy` resolves to `/etc/profiles/per-user/nnon/bin/agy`.

---

## 7. GPG & Declarative Git Commit Auto-Signing
- **Implementation:**
  - Configured `programs.gpg` with `mutableKeys = true;` and `mutableTrust = true;`.
  - Deployed `services.gpg-agent` with native KDE Plasma Wayland pinentry (`pkgs.pinentry-qt`).
  - Key `9106CA7732D04633` (`lithinnon (lunar-qualia) <49898465+lithinnon@users.noreply.github.com>`) imported and set to `[ultimate]` trust.
  - Configured `programs.git.signing = { key = "9106CA7732D04633"; signByDefault = true; };` with `safe.directory = "*"`.
