# Hardware trait: AMD Radeon GPU (Vulkan, VA-API, RADV)
{ ... }:

{
  flake.nixosModules.hw-gpu-amd = { config, pkgs, lib, ... }: {
    # Hardware Accelerated Graphics & 32-bit Vulkan
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva-utils
        vulkan-loader
        vulkan-validation-layers
      ];
    };
  };
}
