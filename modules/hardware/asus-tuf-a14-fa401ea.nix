# Dendritic module: ASUS TUF A14 FA401EA (AMD Strix Halo / Ryzen AI Max+ 392)
{ inputs, ... }:

{
  flake.nixosModules.hardware-asus-tuf-a14-fa401ea = { config, pkgs, lib, ... }: {
    # Kernel Parameters matching tuned Fedora installation
    boot.kernelParams = [
      "amd_pstate=active"
      "amdgpu.gpu_recovery=1"
      "iommu=pt"
      "amdgpu.dcdebugmask=0x800"
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.max_pool_percent=15"
    ];

    # Hardware quirks & modprobe tuning (TTM page limits, Realtek WiFi ASPM, Bluetooth sleep)
    boot.extraModprobeConfig = ''
      options ttm pages_limit=5994012
      options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y disable_clkreq=y
      options rtw89_core disable_ps_mode=y
      options btusb enable_autosuspend=N
    '';

    # Sysfs permissions for amdgpu-boost performance switcher
    systemd.tmpfiles.rules = [
      "z /sys/class/drm/card1/device/power_dpm_force_performance_level 0666 root root -"
    ];

    # ASUS Laptop Control Daemon (asusd & asusctl)
    services.asusd.enable = true;

    # Hardware Accelerated Graphics & Vulkan
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva-utils
        vulkan-loader
        vulkan-validation-layers
      ];
    };

    # Pipewire High-Performance Audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # 48 GiB Disk Swapfile on dedicated @swap BTRFS subvolume (nodatacow)
    swapDevices = [
      {
        device = "/swap/swapfile";
        size = 48 * 1024; # 48 GiB (49,152 MiB)
      }
    ];

    # YubiKey 5C NFC Support (SmartCard Daemon & CCID/FIDO2 Udev Rules)
    services.pcscd.enable = true;
    services.udev.packages = with pkgs; [
      yubikey-personalization
    ];

    # Keychron Mouse & Peripherals Udev Rules (VID 3434)
    services.udev.extraRules = ''
      # Keychron M6 Mouse (USB/Dongle)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="d064", MODE="0666", TAG+="uaccess", TAG+="udev-acl"

      # General Keychron Device (VID 3434)
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0666", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}
