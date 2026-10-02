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

        settings = {
          mode = lib.mkOption {
            type = lib.types.enum [
              "smart"
              "force"
              "disabled"
            ];
            default = "smart";
            description = "Operating mode for AMD GPU Boost governor.";
          };

          upThreshold = lib.mkOption {
            type = lib.types.ints.between 1 100;
            default = 20;
            description = "GPU busy percentage threshold to trigger performance boost.";
          };

          downThreshold = lib.mkOption {
            type = lib.types.ints.between 1 100;
            default = 12;
            description = "GPU busy percentage threshold to return to standard clock.";
          };

          cooldownSeconds = lib.mkOption {
            type = lib.types.float;
            default = 3.0;
            description = "Cooldown hysteresis duration before throttling down.";
          };

          autoRefreshRate = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to dynamically switch display refresh rate based on power state.";
          };
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

        environment.etc."amdgpu-boost.conf".text = ''
          # Generated declaratively by NixOS services.amdgpu-boost
          CARD=${cfg.card}
          MODE=${cfg.settings.mode}
          SMART_UP_THRESHOLD=${toString cfg.settings.upThreshold}
          SMART_DOWN_THRESHOLD=${toString cfg.settings.downThreshold}
          SMART_COOLDOWN_SECONDS=${toString cfg.settings.cooldownSeconds}
          AUTO_REFRESH_RATE=${lib.boolToString cfg.settings.autoRefreshRate}
        '';
      };
    };
}
