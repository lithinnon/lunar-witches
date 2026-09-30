# Comprehensive NixOS Migration & Restoration Manual: `lunar-qualia`

**Target Machine:** ASUS TUF Gaming A14 FA401EA (`lunar-qualia`)  
**Hardware Platform:** AMD Ryzen AI Max+ 392 (Strix Halo APU, Radeon 8060S / `gfx1151`, NPU `aie2p`)  
**Source OS:** Fedora 44 (Workstation)  
**Destination OS:** NixOS 26.05 (Dendritic Flake + Home Manager + BTRFS + KDE Plasma 6 Wayland)  
**Repository Working Directory:** [`/home/nnon/lunar-witches`](file:///home/nnon/lunar-witches)  
**Migration Storage Backup:** SD Card `Tera` at [`/run/media/nnon/Tera/nixos-migration/`](file:///run/media/nnon/Tera/nixos-migration/)

---

## 1. Migration Architecture & Current State Overview

```mermaid
flowchart TD
    subgraph S1["Phase 1: Backup & Preparation (Fedora 44 - 100% Completed)"]
        B1["User Data Backed Up (55 GB on SD Card Tera)"]
        B2["Flatpak & Browser Profiles Staged"]
        B3["Dendritic Flake Created & Verified in git"]
    end

    subgraph S2["Phase 2: Final Pre-Reboot Sync (Live Fedora)"]
        F1["Copy /home/nnon/lunar-witches to Tera"]
        F2["Copy /home/nnon/.gemini to Tera"]
        F3["Reboot into NixOS 26.05 Live USB"]
    end

    subgraph S3["Phase 3: Disk Partitioning & Subvolumes (Installer)"]
        D1["Format /dev/nvme0n1p1 (FAT32, Label: ESP)"]
        D2["Format /dev/nvme0n1p2 (BTRFS, Label: NIXOS)"]
        D3["Create BTRFS Subvolumes: @, @home, @nix, @snapshots, @log, @swap"]
        D4["Mount Subvolumes under /mnt"]
    end

    subgraph S4["Phase 4: Flake Installation (Installer)"]
        I1["Mount SD Card Tera under /mnt/run/media/nnon/Tera"]
        I2["Run nixos-install using flake from SD card"]
        I3["Set User Password for nnon & Root"]
        I4["Reboot into New NixOS System"]
    end

    subgraph S5["Phase 5: Post-Install Data Restore (NixOS)"]
        R1["Restore /home/nnon/ directories from Tera"]
        R2["Restore Flatpak Waterfox Profile"]
        R3["Migrate Bottles to Native ~/.local/share/bottles/"]
        R4["Verify Syncthing, KeePassXC, Brave & YubiKey"]
    end

    S1 --> S2 --> S3 --> S4 --> S5
```

---

## 2. Inventory & Backup Audit

All critical personal files, configurations, credentials, and app states have been copied and verified on SD Card partition `/run/media/nnon/Tera/nixos-migration/`:

| Component | Fedora Source Path | Backup Target on SD Card | Status | Notes |
| :--- | :--- | :--- | :---: | :--- |
| **Brave Profile** | `~/.config/BraveSoftware` | `.../home/nnon/.config/BraveSoftware` | ✅ Backed up | Includes extensions, tabs, history |
| **KWallet Keys** | `~/.local/share/kwalletd` | `.../home/nnon/.local/share/kwalletd` | ✅ Backed up | **Mandatory** for Brave cookie/password decryption |
| **Waterfox Profile** | `~/.var/app/net.waterfox.waterfox` | `.../flatpak_migration/net.waterfox.waterfox` | ✅ Backed up | Restores seamlessly to Flatpak Waterfox |
| **Syncthing Identity** | `~/.local/state/syncthing` | `.../home/nnon/.local/state/syncthing` | ✅ Backed up | `cert.pem` & `key.pem` maintain existing cluster ID |
| **KeePassXC Vault** | `~/Sync` & `~/.config/keepassxc` | `.../home/nnon/Sync`, `.../.config/keepassxc` | ✅ Backed up | Contains master password databases |
| **YubiKey 5C NFC** | Host CCID & Udev | Declared in Flake | ✅ Configured | `pcscd` + `libu2f-host` + `yubikey-manager` |
| **Bottles & ProtonPlus** | `~/.var/app/com.usebottles.bottles`, `~/.config/ProtonPlus` | `.../flatpak_migration/`, `.../.config/ProtonPlus` | ✅ Backed up | Native `pkgs.bottles` & `pkgs.protonplus` in Flake |
| **Digital Logic Sim** | `~/.digital.cfg` | `.../home/nnon/.digital.cfg` | ✅ Backed up | Native `pkgs.digital` declared in Home Manager |
| **VS Code Config** | `~/.config/Code`, `~/.local/share/vscode` | `.../home/nnon/.config/Code` | ✅ Backed up | `programs.vscode` + `nix-ld` for unpatched extensions |
| **CU Academic Data** | `~/CU` | `.../home/nnon/CU` | ✅ Backed up | Cleaned and preserved |
| **SSH Keys** | `~/.ssh` | `.../home/nnon/.ssh` | ✅ Backed up | Permissions preserved (`-aHAX`) |
| **Fastfetch & Agents** | `~/.config/fastfetch`, `.agents` | `.../home/nnon/.config/` | ✅ Backed up | Ready for deployment |
| **GPU Boost Utility** | `~/.local/bin/amdgpu-boost` | `.../home/nnon/.local/bin/amdgpu-boost` | ✅ Backed up | Integrated into systemd user service in Flake |
| **BullVPN Client** | `~/.local/bin/bullvpn` | `.../home/nnon/.local/bin/bullvpn` | ✅ Backed up | Dependencies (`nftables`, `wireguard-tools`) in Flake |
| **WuWa Config Sync** | `~/.local/bin/wuwa-config-sync` | `.../home/nnon/.local/bin/wuwa-config-sync` | ✅ Backed up | Core engine `acg_config_sync.py` bundled alongside |
| **Keychron Rules** | `/etc/udev/rules.d/99-keychron.rules` | `.../system/99-keychron.rules` | ✅ Backed up | Implemented in `asus-tuf-a14-fa401ea.nix` |
| **GGUF Models** | `~/.local/share/ggufs` | Manifest recorded | ℹ️ Skipped | Inventory documented for fresh download |
| **Antigravity Suite** | Antigravity 2.0 & CLI | Flake input `jacopone/antigravity-nix` | ✅ Configured | `google-antigravity` & `google-antigravity-cli` in Flake |
| **Nix Flake Tree** | `/home/nnon/lunar-witches` | Staged & Committed in Git | ⏳ Step 2 | Copied as final step before rebooting |
| **Antigravity State** | `/home/nnon/.gemini` | Live in use | ⏳ Step 2 | Copied as final step before rebooting |

---

## 3. Step-by-Step Installation Guide (Dry Run Execution)

### Step 3.1: Final Pre-Reboot Backup (Run on Fedora)

> [!IMPORTANT]
> Run these commands right before you shut down Fedora to boot into your NixOS Live USB. This copies the active agent data and the Git flake repository.

```bash
# 1. Sync the flake repository
rsync -aHAX --info=progress2 /home/nnon/lunar-witches/ /run/media/nnon/Tera/nixos-migration/lunar-witches/

# 2. Sync the complete Antigravity CLI and state directory
rsync -aHAX --info=progress2 /home/nnon/.gemini/ /run/media/nnon/Tera/nixos-migration/home/nnon/.gemini/

# 3. Flush disk buffers
sync
```

---

### Step 3.2: Boot Live Installer & Prepare Storage Layout

Boot the machine using the prepared NixOS Live USB (`nixos-graphical-26.05.10304.6d663c0533ff-x86_64-linux.iso`). Open a terminal (Konsole) in the live environment.

#### 1. Partition the NVMe SSD (`/dev/nvme0n1`)
We will create a 1 GiB EFI System Partition and allocate the rest of the disk to BTRFS:

```bash
sudo -i

# Clear existing partition table (Ensure all data on nvme0n1 is backed up!)
sgdisk -Z /dev/nvme0n1

# Partition 1: 1024 MiB EFI System Partition (type EF00)
sgdisk -n 1:0:+1024M -t 1:ef00 -c 1:"ESP" /dev/nvme0n1

# Partition 2: Remaining space for BTRFS (type 8300)
sgdisk -n 2:0:0 -t 2:8300 -c 2:"NIXOS" /dev/nvme0n1

# Inform the kernel of partition table changes
partprobe /dev/nvme0n1
```

#### 2. Format the Partitions
```bash
# Format Partition 1 as FAT32 with label ESP
mkfs.fat -F 32 -n ESP /dev/nvme0n1p1

# Format Partition 2 as BTRFS with label NIXOS
mkfs.btrfs -f -L NIXOS /dev/nvme0n1p2
```

#### 3. Create BTRFS Subvolumes
```bash
# Mount the root BTRFS volume temporarily
mount -t btrfs /dev/disk/by-label/NIXOS /mnt

# Create subvolumes matching hardware.nix
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@swap

# Unmount the temporary root mount
umount /mnt
```

#### 4. Mount Subvolumes to Target Directory (`/mnt`)
```bash
# Mount root subvolume
mount -o subvol=@,noatime,compress=zstd:1 /dev/disk/by-label/NIXOS /mnt

# Create mount points
mkdir -p /mnt/{boot,home,nix,.snapshots,var/log,swap}

# Mount secondary subvolumes
mount -o subvol=@home,noatime,compress=zstd:1 /dev/disk/by-label/NIXOS /mnt/home
mount -o subvol=@nix,noatime,compress=zstd:1 /dev/disk/by-label/NIXOS /mnt/nix
mount -o subvol=@snapshots,noatime,compress=zstd:1 /dev/disk/by-label/NIXOS /mnt/.snapshots
mount -o subvol=@log,noatime,compress=zstd:1 /dev/disk/by-label/NIXOS /mnt/var/log
mount -o subvol=@swap,nodatacow /dev/disk/by-label/NIXOS /mnt/swap

# Mount EFI System Partition
mount /dev/disk/by-label/ESP /mnt/boot

# Initialize nodatacow swap directory and pre-allocate swapfile
chattr +C /mnt/swap
btrfs filesystem mkswapfile --size 48g /mnt/swap/swapfile
```

---

### Step 3.3: Network Setup, SD Card Mount & `nixos-install`

> [!IMPORTANT]
> Ensure you are connected to the Internet (Wi-Fi or Ethernet) in the Live environment before running `nixos-install`.

```bash
# 1. Mount the SD Card at an isolated mount point outside of /mnt
#mkdir -p /mnt-tera
#mount /dev/disk/by-label/Tera /mnt-tera

# 2. Tell Git to trust repositories across different UIDs (prevents 'dubious ownership' errors)
git config --global --add safe.directory '*'

# 3. Trust the Lantian CachyOS binary cache in the Live installer to avoid compiling from source
mkdir -p /root/.config/nix
cat << 'EOF' >> /root/.config/nix/nix.conf
extra-substituters = https://attic.xuyh0120.win/lantian https://nix-community.cachix.org
extra-trusted-public-keys = lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
EOF

# 4. Run nixos-install using the pre-configured dendritic flake
nixos-install \
  --flake /run/media/nixos/Tera/nixos-migration/lunar-witches#lunar-qualia \
  --no-root-password \
  --option extra-substituters https://attic.xuyh0120.win/lantian \
  --option extra-trusted-public-keys lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=

# 5. Set password for your user account (nnon) so you can log into KDE Plasma
nixos-enter --root /mnt -c "passwd nnon"

# 6. Unmount the SD card before rebooting
umount /mnt-tera
```

---

### Step 3.4: First Boot & User Data Restoration

Unmount filesystems and reboot into your fresh NixOS system:

```bash
umount -R /mnt
reboot
```

Log in to the KDE Plasma 6 desktop as user `nnon`. Open Konsole and restore your files:

```bash
# 1. Restore Home Directory Data (Documents, Downloads, CU, Sync, Pictures, .ssh, .gemini, etc.)
rsync -aHAX --info=progress2 /run/media/nnon/Tera/nixos-migration/home/nnon/ /home/nnon/

# 2. Restore Flake Repository into working directory
rsync -aHAX --info=progress2 /run/media/nnon/Tera/nixos-migration/lunar-witches/ /home/nnon/lunar-witches/

# 3. Restore Waterfox Flatpak (The only approved Flatpak)
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub net.waterfox.waterfox
mkdir -p ~/.var/app
rsync -aHAX --info=progress2 /run/media/nnon/Tera/nixos-migration/flatpak_migration/net.waterfox.waterfox/ ~/.var/app/net.waterfox.waterfox/

# 4. Migrate Bottles Data to Native NixOS Bottles
mkdir -p ~/.local/share/bottles/
rsync -aHAX --info=progress2 /run/media/nnon/Tera/nixos-migration/flatpak_migration/com.usebottles.bottles/data/bottles/ ~/.local/share/bottles/

# Fix bottle path references inside YAML configurations (changing Flatpak path to native path)
find ~/.local/share/bottles/bottles/ -name "*.yml" -exec sed -i 's|/home/nnon/.var/app/com.usebottles.bottles/data/bottles|/home/nnon/.local/share/bottles|g' {} +

# 5. Fix Academic Course Symlink (I2CEDT)
ln -sfn "/home/nnon/.local/share/bottles/bottles/I2CEDT/drive_c/users/nnon/Documents/I2CEDT" "/home/nnon/CU/Y1/I2CEDT"

# 6. Ensure Correct SSH Permissions
chmod 700 /home/nnon/.ssh
chmod 600 /home/nnon/.ssh/id_* 2>/dev/null || true
chmod 644 /home/nnon/.ssh/*.pub 2>/dev/null || true
```

---

## 4. Post-Migration Verification Checklist

1. **Brave Browser:** Open Brave. Verify all tabs, extensions, bookmarks, and logins are active. (KWallet decrypts secrets automatically upon login).
2. **Waterfox (Flatpak):** Launch Waterfox. Verify history, cookies, and pinned tabs are preserved.
3. **Syncthing:** Run `systemctl --user status syncthing` or check `http://127.0.0.1:8384`. Verify the device ID matches the previous Fedora install and other cluster nodes show connected without re-pairing.
4. **KeePassXC & YubiKey:** Insert YubiKey 5C NFC. Open KeePassXC and open the password database in `~/Sync/`. Verify HMAC-SHA1 challenge-response unlocks the database.
5. **Digital Simulator:** Launch `digital` from application menu or CLI. Open class `.dig` circuits and verify simulator runs smoothly.
6. **Visual Studio Code:** Run `code /home/nnon/lunar-witches`. Verify extensions work cleanly via `nix-ld`.
7. **GPU Screen Recorder:** Open `gpu-screen-recorder-gtk`. Verify AMD AMF / VA-API hardware encoding captures at native resolution without dropped frames.
8. **Bottles & BullVPN:**
   - Launch `bottles`. Verify bottles (`Apps`, `I2CEDT`) appear and launch.
   - Run `bullvpn status`. Verify Windows token is read from native Bottles path and NetworkManager imports WireGuard/OpenVPN profiles.
9. **AMD GPU Boost:** Run `systemctl --user status amdgpu-boost` and `gpu-boost --status`. Verify dynamic switching works as expected.
10. **Antigravity CLI:** Run `agy whoami` or `agy --version`. Verify state is retained under `~/.gemini/`.
11. **SDDM Wallpaper & Settings Sync:** Open **System Settings** → **Colors & Themes** → **Login Screen (SDDM)** and click **Apply Plasma Settings...** at the bottom right to sync your desktop wallpaper to the login screen.

---

## 5. Ongoing Maintenance & Day-to-Day Operations

- **Rebuilding System:**  
  ```bash
  nh os switch /home/nnon/lunar-witches
  ```
- **Updating Inputs:**  
  ```bash
  nix flake update /home/nnon/lunar-witches
  nh os switch /home/nnon/lunar-witches
  ```
- **Automatic Housekeeping:**  
  System garbage collection runs automatically weekly (`options = "--delete-older-than 7d"`).  
  To trigger an immediate manual clean:
  ```bash
  nh clean all --keep 3
  ```
