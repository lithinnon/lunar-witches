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
- **Symptom:** `mem-ttm` or scripts in `~/.local/bin` were not visible in newly launched Fish shells despite `home.sessionPath` being configured.
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

---

## 8. External Game Storage & Mount Flags (`noexec` Trap)
- **Symptom:** Steam Proton games and anime game launchers (such as Honkai Impact 3rd) on the external SD Card (`/run/media/nnon/Tera`) failed to boot or execute binaries.
- **Cause:** In [`hosts/lunar-qualia/hardware.nix`](file:///home/nnon/lunar-witches/hosts/lunar-qualia/hardware.nix), the mount entry had `options = [ "nofail" "x-systemd.automount" "user" ];`. In standard Linux `/etc/fstab` semantics, the `user` flag implicitly enforces `noexec,nosuid,nodev` as a security precaution, preventing any binaries or Proton scripts from executing directly off the filesystem.
- **Resolution:** Replaced `user` with `[ "defaults" "nofail" "x-systemd.automount" "exec" ]`.

---

## 9. Electron Autostart `SIGILL` on NixOS (Equibop)
- **Symptom:** Equibop crashed on desktop login with `Signal: 4 (ILL) si_code: ILL_ILLOPN` in `/var/lib/systemd/coredump/`.
- **Cause:** When Equibop's built-in "Run at Startup" option is toggled, it resolves `process.execPath`. On NixOS, this pointed directly to the raw, unwrapped binary `/nix/store/...-electron-unwrapped-43.6.0/libexec/electron/electron` inside `~/.config/autostart/equibop.desktop`, bypassing the required Nix dynamic linker wrapper (`steam-run`/`wrapElectron`/`nix-ld`) and Wayland flags.
- **Resolution:** Replaced `Exec` in `~/.config/autostart/equibop.desktop` with `equibop --start-minimized` and marked the file read-only (`chmod 444`) to prevent the app from overwriting it.

---

## 10. Wine Drive Letter Conflict with USB Installer Devices (`honkers-launcher`)
- **Symptom:** `honkers-launcher` exited immediately after clicking "Play". Game logs reported:
  ```text
  wine: could not open working directory L"G:\\", starting in the Windows directory.
  Failed to create process L"BH3.exe": 2
  ```
- **Cause:** `config.json` had `"game_folder": "G"`. However, Wine auto-scanned block devices on startup and discovered `/dev/sda2` (the SanDisk NixOS USB installer stick plugged into the system), generating a raw block device symlink `dosdevices/g:: -> /dev/sda2`. Because `g::` was bound to a block device, Wine refused to treat `G:\` as a filesystem directory, breaking `BH3.exe` execution.
- **Resolution:**
  1. Updated `game_folder` from `G` to `X` in [`~/.local/share/honkers-launcher/config.json`](file:///home/nnon/.local/share/honkers-launcher/config.json).
  2. Linked `~/.local/share/honkers-launcher/prefix/dosdevices/x:` to `/run/media/nnon/Tera/Honkai Impact`.
  3. Ensured `BH3.exe` had execute permissions (`chmod +x`).
  4. Verified execution succeeds inside `steam-run` with NTSync.

---

## 11. KDE Plasma 6 SDDM Settings Module & Wallpaper Persistence
- **Symptom:** Setting a custom background or clicking "Apply Plasma Settings..." in the SDDM KCM (`Login Screen (SDDM)`) does not persist after reboot or switch.
- **Cause:**
  1. On NixOS, the Breeze SDDM theme is located in the read-only `/nix/store`. The KCM helper attempts to write `theme.conf.user` into `/usr/share/sddm/themes/breeze/` or `/nix/store`, which fails or is silently ignored.
  2. The `sddm` system user cannot traverse `/home/nnon/` (permission 0700) to read user wallpapers.
  3. SDDM's Qt6 runtime lacks `qtimageformats` by default, preventing rendering of modern image formats like WebP.
- **Resolution:**
  - Expose `suites.desktop.plasma.sddm.background` in `modules/suites/desktop/plasma.nix`.
  - Inject `theme.conf.user` into `share/sddm/themes/breeze/` via `pkgs.writeTextDir`, which `buildEnv` automatically merges into the system environment.
  - Add `pkgs.kdePackages.qtimageformats` to `services.displayManager.sddm.extraPackages`.
  - Store the wallpaper in `hosts/<hostname>/assets/` and assign it in `hosts/<hostname>/default.nix`.
