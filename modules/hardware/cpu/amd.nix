# Hardware trait: AMD CPU
{ ... }:

{
  flake.nixosModules.hw-cpu-amd = { config, lib, ... }: {
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    boot.kernelParams = [
      "amd_pstate=active"
      "iommu=pt"
    ];
  };
}
