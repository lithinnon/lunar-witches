# Hardware trait: AMD Unified Memory Architecture (APU / Strix Halo / Phoenix)
{ self, ... }:

{
  flake.nixosModules.hw-gpu-amd-uma = { config, lib, pkgs, ... }:
  let
    cfg = config.hardware.amdgpu.uma;
  in {
    imports = [
      self.nixosModules.hw-gpu-amd
    ];

    options.hardware.amdgpu.uma = {
      enable = lib.mkEnableOption "AMD Unified Memory Architecture (APU) optimizations";

      ttmPagesLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 5862940;
        description = "Explicit TTM page allocation limit. If null, kernel default is used.";
      };

      overrideGfxVersion = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "11.5.1";
        description = "HSA override GFX version for ROCm compatibility (e.g. 11.5.1 for Strix Halo).";
      };

      rocmArch = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "gfx1151";
        description = "Target ROCm GPU architecture for PyTorch.";
      };

      disableDcIps = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Disable AMD Display Core Idle Power States (IPS) via amdgpu.dcdebugmask=0x800 to fix sleep/suspend hangs on newer APU display engines.";
      };
    };

    config = lib.mkIf cfg.enable {
      boot.kernelParams = lib.optional cfg.disableDcIps "amdgpu.dcdebugmask=0x800";

      boot.extraModprobeConfig = lib.optionalString (cfg.ttmPagesLimit != null) ''
        options ttm pages_limit=${toString cfg.ttmPagesLimit}
      '';

      environment.sessionVariables = lib.mkMerge [
        (lib.mkIf (cfg.overrideGfxVersion != null) {
          HSA_OVERRIDE_GFX_VERSION = cfg.overrideGfxVersion;
        })
        (lib.mkIf (cfg.rocmArch != null) {
          PYTORCH_ROCM_ARCH = cfg.rocmArch;
        })
      ];

      # Standalone TTM inspector utility
      environment.systemPackages = [
        pkgs.amd-ttm
      ];
    };
  };
}
