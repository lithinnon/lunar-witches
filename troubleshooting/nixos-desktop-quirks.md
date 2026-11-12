# NixOS Desktop Operational Quirks & Troubleshooting Runbook

During the migration and post-install configuration, several notable edge cases and NixOS nuances were encountered and resolved.

---

## 1. ESP Random Seed Security Warning
- **Symptom:**
  ```text
  ⚠️ Mount point '/boot' which backs the random seed file is world accessible, which is a security hole! ⚠️
  ```
- **Cause:** Default VFAT mount options in systemd-boot allow standard world-readable permissions (0022), leaving `/boot/loader/random-seed` readable by unprivileged users.
- **Resolution:** Added `options = [ "fmask=0077" "dmask=0077" ];` to `fileSystems."/boot"` in [`hosts/lunar-qualia/hardware.nix`](../../hosts/lunar-qualia/hardware.nix#L18).

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
- **Resolution:** Added `home-manager.backupFileExtension = "backup";` to the Home Manager block in [`hosts/lunar-qualia/default.nix`](../../hosts/lunar-qualia/default.nix#L26).

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
- **Cause:** In [`hosts/lunar-qualia/hardware.nix`](../../hosts/lunar-qualia/hardware.nix), the mount entry had `options = [ "nofail" "x-systemd.automount" "user" ];`. In standard Linux `/etc/fstab` semantics, the `user` flag implicitly enforces `noexec,nosuid,nodev` as a security precaution, preventing any binaries or Proton scripts from executing directly off the filesystem.
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

---

## 12. OpenSSH Empty `SSH_ASKPASS` Execution Failure with Encrypted Keys
- **Symptom:**
  ```text
  $ ssh -T git@github.com
  ssh_askpass: exec(): No such file or directory
  git@github.com: Permission denied (publickey).
  ```
- **Cause:**
  1. NixOS upstream `programs.ssh` defines:
     ```nix
     environment.variables.SSH_ASKPASS = lib.optionalString cfg.enableAskPassword cfg.askPassword;
     ```
  2. Because `programs.ssh.enableAskPassword` defaults to `false`, `lib.optionalString false ...` evaluates to `""`.
  3. NixOS exports all attributes defined in `environment.variables` into `/etc/set-environment`, creating:
     ```bash
     export SSH_ASKPASS=""
     ```
  4. When combined with `SSH_ASKPASS_REQUIRE="prefer"`, OpenSSH inspects `getenv("SSH_ASKPASS")`. Because the variable exists with length 0, it calls `execve("", ...)`, failing immediately with `ENOENT` (`ssh_askpass: exec(): No such file or directory`) before a passphrase can be entered for encrypted keys.
- **Resolution:**
  - Set `programs.ssh.enableAskPassword = true;` and `programs.ssh.askPassword = "/run/current-system/sw/bin/conduct";` in [`modules/suites/desktop/plasma.nix`](../../modules/suites/desktop/plasma.nix).
  - Explicitly export `SSH_ASKPASS = "/run/current-system/sw/bin/conduct";` in `home.sessionVariables` in [`modules/users/nnon/shell.nix`](../../modules/users/nnon/shell.nix).

---

## 13. Flatpak Sandboxed Apps Missing Host Fonts (CJK "Tofu" / Dangling Symlinks)
- **Symptom:** Flatpak applications (e.g. Waterfox) fail to render Chinese, Japanese, or Korean characters properly, showing empty boxes ("tofu") or falling back to generic Western fonts despite `noto-fonts-cjk-sans` / `noto-fonts-cjk-serif` being installed on NixOS.
- **Cause:**
  1. Flatpak's Bubblewrap container isolates the host filesystem and bind-mounts host fonts from `/run/current-system/sw/share/X11/fonts` into `/run/host/fonts`.
  2. On NixOS, `/run/current-system/sw/share/X11/fonts` consists entirely of symlinks pointing to individual package paths under `/nix/store/...`.
  3. By default, `/nix/store` is not exposed inside Flatpak sandboxes (except for specific portal-exported application assets).
  4. Consequently, every symlink in `/run/host/fonts` becomes a dangling/broken link inside the sandbox, forcing Fontconfig to fall back to the minimal Western fonts bundled in the Freedesktop runtime (DejaVu, FreeSans, Liberation).
- **Resolution:**
  - Declaratively create `/var/lib/flatpak/overrides/global` via `systemd.tmpfiles.rules` in [`modules/suites/desktop/apps.nix`](../../modules/suites/desktop/apps.nix):
    ```nix
    systemd.tmpfiles.rules = [
      "d /var/lib/flatpak/overrides 0755 root root -"
      "L+ /var/lib/flatpak/overrides/global - - - - ${pkgs.writeText "flatpak-global-override" ''
        [Context]
        filesystems=/nix/store:ro;
      ''}"
    ];
    ```
  - Define explicit font fallback priorities in [`modules/suites/desktop/fonts.nix`](../../modules/suites/desktop/fonts.nix) using `fonts.fontconfig.defaultFonts` to ensure `Noto Sans CJK JP/SC/KR` are prioritized when generic `sans-serif` or `serif` is requested.
  - Rebuilt Flatpak Fontconfig cache via `flatpak run --command=fc-cache <APP_ID> -r`.

---

## 14. KDE Plasma Application Indexing across NixOS Symlink Swaps
- **Symptom:** Newly installed GUI applications or updated `.desktop` files (e.g. `r2modman`, `google-antigravity-ide`) do not appear in the Kickoff application menu or KRunner search taskbar after `nh os switch`, requiring manual session restart or shell relaunch.
- **Cause:**
  1. On standard distributions, package managers create/modify files in `/usr/share/applications`, triggering inotify (`KDirWatch`) so Plasma auto-reloads.
  2. On NixOS, `/run/current-system` is an atomic symlink swap to a new `/nix/store/...` directory. Because the underlying Nix store directory inode never receives in-place filesystem events, `KDirWatch` never fires.
  3. Abruptly restarting `plasmashell` disrupts open window tracking and arrangement in Icons-only Task Manager (`icontasks`).
- **Resolution:**
  - Provisioned `home.activation.kbuildsycoca` in [`modules/users/nnon/plasma.nix`](../../modules/users/nnon/plasma.nix) to automatically run `XDG_MENU_PREFIX=plasma- ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental` during home-manager activation with proper `LOCALE_ARCHIVE` and `XDG_DATA_DIRS`, immediately updating KSycoca (`~/.cache/ksycoca6_*`) without restarting `plasmashell`.
  - **Kickoff Search Cache vs. Tree View Nuance:** Kickoff's category browse tree (`AppsModel`) reads KSycoca directly and immediately shows new items. However, Kickoff's search bar uses an in-memory `RunnerModel` (`ServiceRunner`) embedded inside `plasmashell` that caches queries. Standalone KRunner (`Alt+Space`) picks up the new cache right away because it spawns fresh. To force Kickoff's in-memory search model to re-instantiate cleanly **without restarting `plasmashell`** (which would disrupt taskbar window grouping and pinned tasks):
    - Right-click the Kickoff launcher icon -> **"Show Alternatives..."** -> select **"Application Menu"** -> **Switch**.
    - Right-click the icon -> **"Show Alternatives..."** -> select **"Application Launcher"** -> **Switch**.
    - This recreates Kickoff's QML engine in ~3 seconds with zero screen flicker and 100% window tracking preservation.

---

## 15. Privilege Escalation Failure in Antigravity IDE Integrated Terminal (`NoNewPrivs`)
- **Symptom:**
  Running `nh os switch`, `nh os test`, or any command invoking `sudo` from the integrated terminal inside Google Antigravity IDE fails during activation:
  ```text
  Error: 
     0: Activation (test) failed
     1: Activating configuration (exit status ExitStatus(Exited(1)))
        stderr:
        sudo: The "no new privileges" flag is set, which prevents sudo from running as root.
        sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
  ```
- **Cause:**
  1. `google-antigravity-ide` is packaged on NixOS using `buildFHSEnv` (`antigravity-nix`), which wraps the application inside an unprivileged Bubblewrap (`bwrap`) container.
  2. Bubblewrap initializes Linux user namespaces and sets `PR_SET_NO_NEW_PRIVS = 1` (`NoNewPrivs: 1` in `/proc/self/status`).
  3. Every child process spawned by the IDE—including integrated terminal shells (Fish, Bash, Zsh)—inherits this flag.
  4. While Nix evaluation and package builds succeed without root privileges, the configuration activation phase (`switch-to-configuration`) executes `sudo`.
  5. The Linux kernel strictly prevents setuid binaries from escalating privileges when `NoNewPrivs` is set, causing `sudo` to immediately terminate.
- **Resolution:**
  - **Permanent Fix (Non-FHS Package):** Use the `no-fhs` variant (`google-antigravity-ide-no-fhs` via `autoPatchelfHook`) in `suite-ai-antigravity`. This eliminates the Bubblewrap container and `NoNewPrivs` flag entirely, allowing `sudo` and `nh os switch` to run natively in the integrated terminal:
    ```bash
    NH_SUDO_ASKPASS=/run/current-system/sw/bin/conduct nh os switch /home/nnon/lunar-witches
    ```
  - **Legacy FHS Workarounds (if using buildFHSEnv):**
    - **External Host Terminal:** Run from a standalone terminal (Konsole, Ghostty) where `NoNewPrivs: 0`.
    - **IDE Terminal Escape (`systemd-run`):** Escape the Bubblewrap user namespace by dispatching through systemd:
      ```bash
      systemd-run --user --pty --same-dir nh os switch /home/nnon/lunar-witches
      ```
  - **Dry-Run / Build Only:** For configuration syntax and build verification without activation:
    ```bash
    nh os build /home/nnon/lunar-witches --dry --json # (structured JSON output for automated agents)
    # or build the generation:
    nh os build /home/nnon/lunar-witches
    ```

---

## 16. Plasma Wayland Relog Crash with `linger = true` & XDG Autostart Race
- **Symptom:** Logging out and back into Plasma 6 Wayland triggered DrKonqi crashes in `.plasma-fallback-session-restore-wrapped`, `.kdeconnectd-wrapped`, and `.DiscoverNotifier-wrapped`. Journal logs showed `graphical-session.target` stayed active for hours (`linger = true`) across logins, `xdg-desktop-portal-kde` restarted on logout, and XDG autostart services (`app-*@autostart.service`) started before `plasma-workspace.target`.
- **Cause:**
  1. `plasma-kwin_wayland.service` has `BindsTo=graphical-session.target` instead of `PartOf`, and with `users.users.nnon.linger = true`, `user@1000.service` stays running after logout. Any portal/D-Bus activation during logout keeps `graphical-session.target` alive across relogins, causing immediate next-login autostart launches to race compositor startup.
  2. Additionally, missing `th_TH.UTF-8` locale compilation (`Detected locale "C"`) caused Qt fallback locale warnings when `~/.config/plasma-localerc` requested Thai regional formats.
- **Resolution:**
  - Added `plasma-kwin_wayland` drop-in (`overrideStrategy = "asDropin"`, `restartIfChanged = false`, `enableDefaultPath = false`) in [`modules/suites/desktop/plasma.nix`](../../modules/suites/desktop/plasma.nix) to unset `WAYLAND_DISPLAY`/`DISPLAY` and run `systemctl --user stop --no-block graphical-session.target` in `ExecStopPost`.
  - Added `app-.service` drop-in ordering XDG autostart apps `After=plasma-workspace.target`.
  - Added `i18n.extraLocales = [ "th_TH.UTF-8/UTF-8" ];` in [`hosts/lunar-qualia/default.nix`](../../hosts/lunar-qualia/default.nix).

---

## 17. KeePassXC `Browser Plugin Failure` with Declarative `nativeMessagingHosts`
- **Symptom:** KeePassXC pops up `Could not save the native messaging script file for brave.` on launch when `programs.brave.nativeMessagingHosts` includes `pkgs.keepassxc`.
- **Cause:** Home Manager symlinks `~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json` into `/nix/store`. With `[Browser] Enabled=true`, KeePassXC defaults `UpdateBinaryPath=true` and attempts to overwrite the read-only symlink at startup. (`programs.keepassxc.settings` is avoided because symlinking `keepassxc.ini` into `/nix/store` blocks KeePassXC UI state saves.)
- **Resolution:** In KeePassXC, uncheck **Tools -> Settings -> Browser Integration -> Advanced -> Update native messaging manifest files at startup** (`UpdateBinaryPath=false` in `~/.config/keepassxc/keepassxc.ini`).





