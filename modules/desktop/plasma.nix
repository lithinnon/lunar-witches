# Dendritic module: KDE Plasma 6 Desktop Environment, Wayland, and GUI System Integrations
{ inputs, ... }:

{
  flake.nixosModules.desktop-plasma = { config, pkgs, ... }: {
    # Display Manager (SDDM Wayland) & Plasma 6
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    services.desktopManager.plasma6.enable = true;

    # GPU Screen Recorder (High-performance hardware-accelerated screen capture)
    programs.gpu-screen-recorder.enable = true;

    # KDE Wallet Integration (Critical for seamless Chromium/Brave cookie and password decryption)
    security.pam.services.sddm.kwallet = {
      enable = true;
      forceRun = true;
    };
    security.pam.services.login.kwallet.enable = true;

    # System-wide Session Variables (Inherited by GUI applications & terminal emulators)
    environment.sessionVariables = {
      RADV_EXPERIMENTAL = "bfloat16";
      MESA_VK_TRACE_TRIGGER = "/tmp/mesa_vk_trace_trigger";
      SUDO_ASKPASS = "/run/current-system/sw/bin/ksshaskpass";

      HSA_OVERRIDE_GFX_VERSION = "11.5.1";
      AMD_COMGR_CACHE_ENABLE = "1";
      ROCFFT_KERNEL_CACHE_ENABLE = "1";
      FLASH_ATTENTION_TRITON_AMD_ENABLE = "TRUE";
      PYTORCH_ROCM_ARCH = "gfx1151";

      CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
      AGY_CLI_HIDE_ACCOUNT_INFO = "1";

      NIXOS_OZONE_WL = "1";
    };

    # GUI Utilities and Desktop Packages
    environment.systemPackages = with pkgs; [
      gpu-screen-recorder-gtk
      kdePackages.ksshaskpass
      kdePackages.libkscreen
      kdePackages.sddm-kcm
      kdePackages.plasma-browser-integration
      wl-clipboard
    ];
  };
}
