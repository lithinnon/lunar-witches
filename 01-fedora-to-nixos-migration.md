# Retrospect 01: Fedora 44 to NixOS Migration Journey

## 1. System Context & Hardware
- **Host Device:** ASUS TUF Gaming A14 (FA401EA - `lunar-qualia`)
- **Processor:** AMD Ryzen AI Max+ 392 (16 cores / 32 threads, Zen 5 microarchitecture)
- **Graphics:** AMD Radeon 8060S iGPU (gfx1151, Strix Halo RDNA 3.5 architecture)
- **Memory:** 32 GiB unified LPDDR5X-8000
- **Display:** External 34" Ultrawide (3440x1440 @ 100 Hz, DisplayPort over USB-C) + Internal 14" 2.5K 165Hz IPS
- **Pre-migration State:** Fedora 44 Workstation (kernel 6.14/6.15, GNOME/KDE, btrfs root)
- **Post-migration State:** NixOS 26.11 (Zokor) with CachyOS BORE Zen 4 kernel (`Linux 7.2.8-cachyos`) & KDE Plasma 6.7.5 Wayland

---

## 2. Chronological Milestones

### Phase 1: Planning & Flake Design
1. Defined dendritic flake structure using `flake-parts` at `/home/nnon/lunar-witches`.
2. Segmented architecture into modular components:
   - `modules/core/`: Bootloader, flakes, maintenance, networking, shell, system fonts.
   - `modules/hardware/asus-tuf-a14-fa401ea.nix`: ASUS laptop daemon (`asusd`), graphics switching (`supergfxctl`), smartcards (`pcscd`), sysfs rules for power boost.
   - `modules/desktop/plasma.nix`: KDE Plasma 6 Wayland desktop, SDDM Wayland greeter, display management.
   - `hosts/lunar-qualia/`: Machine-specific hardware generation, filesystem definitions, and user Home Manager profiles.
3. Added the optimized CachyOS kernel input (`nix-cachyos-kernel`) with Zen 4 microarchitecture tuning and BORE (Burst-Oriented Response Enhancer) CPU scheduler.

### Phase 2: Backup & Live Media Preparation
1. Formatted an external SD Card labeled `Tera` (`/dev/mmcblk0p1`, ext4).
2. Performed a full user-space backup of `/home/nnon` (dotfiles, data, Git repositories, KeePassXC databases).
3. Prepared and flashed the graphical NixOS installer image onto a SanDisk USB flash drive.

### Phase 3: Disk Partitioning & Installation
1. Cleaned target NVMe drive (`/dev/nvme0n1`):
   - `nvme0n1p1` (2 GiB): EFI System Partition (`ESP`, vfat, mounted with `fmask=0077, dmask=0077`).
   - `nvme0n1p2` (951.8 GiB): Root partition (`NIXOS`, BTRFS).
2. Created standard subvolume layout:
   - `@` -> `/` (root)
   - `@home` -> `/home` (user profiles)
   - `@nix` -> `/nix` (Nix store)
   - `@snapshots` -> `/.snapshots` (BTRFS snapshots)
   - `@log` -> `/var/log` (systemd journals)
   - `@swap` -> `/swap` (nodatacow, hosting 48 GiB swapfile)
3. Cloned `/home/nnon/lunar-witches` into the chroot and executed `nixos-install --flake .#lunar-qualia`.

### Phase 4: First Boot & Data Restoration
1. Rebooted directly into NixOS 26.11 running the CachyOS BORE kernel under KDE Plasma 6.
2. Verified BTRFS subvolume mounts and automounted the backup SD Card `Tera` at `/run/media/nnon/Tera`.
3. Restored user data and repositories to `/home/nnon/`.
4. Successfully launched live paired programming with Antigravity assistant under the new native NixOS installation.
