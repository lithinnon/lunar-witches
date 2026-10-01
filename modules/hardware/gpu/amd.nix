# Hardware trait: AMD Radeon GPU (Vulkan, VA-API, RADV)
{ ... }:

{
  flake.nixosModules.hw-gpu-amd = { config, pkgs, lib, ... }: {
    boot.kernelParams = [
      "amdgpu.gpu_recovery=1"
      "amdgpu.dcdebugmask=0x800"
    ];

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

    environment.sessionVariables = {
      RADV_EXPERIMENTAL = "bfloat16";
    };
  };
}
