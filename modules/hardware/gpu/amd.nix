# Hardware trait: AMD Radeon GPU (Vulkan, VA-API, RADV, Development & Reset)
{ ... }:

{
  flake.nixosModules.hw-gpu-amd =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      devCfg = config.hardware.amdgpu.development;

      amdgpuResetPkg = pkgs.writeShellScriptBin "amdgpu-reset" ''
        set -euo pipefail
        if [ "$(id -u)" -ne 0 ]; then
          exec sudo -A "$0" "$@"
        fi

        found=0
        for card in /sys/class/drm/card[0-9]*; do
          if [ -e "$card/device/driver" ] && [ "$(basename "$(readlink -f "$card/device/driver")")" = "amdgpu" ]; then
            minor="''${card##*card}"
            node="/sys/kernel/debug/dri/$minor/amdgpu_gpu_recover"
            if [ -e "$node" ]; then
              echo "Triggering AMDGPU recovery on $(basename "$card") (dri/$minor)..."
              cat "$node"
              found=1
            fi
          fi
        done

        if [ "$found" -eq 0 ]; then
          echo "Error: No active AMDGPU recovery node found in /sys/kernel/debug/dri/" >&2
          exit 1
        fi
      '';
    in
    {
      options.hardware.amdgpu.development = {
        enable = lib.mkEnableOption "AMD Radeon GPU profiling & developer tools (RGP, SQTT traces)";

        traceBufferSize = lib.mkOption {
          type = lib.types.str;
          default = "134217728"; # 128 MiB buffer for RGP/SQTT captures
          description = "RADV_THREAD_TRACE_BUFFER_SIZE in bytes for RGP/SQTT captures.";
        };
      };

      config = {
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

        environment.systemPackages = [
          amdgpuResetPkg
        ] ++ lib.optional devCfg.enable pkgs.rgp;

        environment.sessionVariables = lib.mkIf devCfg.enable {
          MESA_VK_TRACE_TRIGGER = "/tmp/mesa_vk_trace_trigger";
          RADV_THREAD_TRACE_BUFFER_SIZE = devCfg.traceBufferSize;
        };
      };
    };
}
