# Opt-in feature: AMD GPU Dynamic Boost & DPM Governor
{ ... }:

{
  flake.nixosModules.feature-amdgpu-boost =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.amdgpu-boost;
    in
    {
      options.services.amdgpu-boost = {
        enable = lib.mkEnableOption "AMD GPU dynamic performance boost & DPM governor";

        card = lib.mkOption {
          type = lib.types.str;
          default = "card1";
          example = "card0";
          description = "DRM card path in /sys/class/drm/ to govern.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.tmpfiles.rules = [
          "z /sys/class/drm/${cfg.card}/device/power_dpm_force_performance_level 0666 root root -"
          "z /sys/devices/system/cpu/cpufreq/boost 0666 root root -"
          "z /sys/devices/system/cpu/cpu*/cpufreq/boost 0666 root root -"
        ];

        environment.systemPackages = [
          pkgs.amdgpu-boost
        ];
      };
    };
}
