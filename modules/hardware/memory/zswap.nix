# Memory management: zswap compressed RAM cache
{ ... }:

{
  flake.nixosModules.hw-memory-zswap =
    { config, lib, ... }:
    let
      cfg = config.hardware.zswap;
    in
    {
      options.hardware.zswap = {
        enable = lib.mkEnableOption "zswap compressed RAM swap cache" // {
          default = true;
        };
        compressor = lib.mkOption {
          type = lib.types.str;
          default = "zstd";
          description = "Compression algorithm for zswap.";
        };
        maxPoolPercent = lib.mkOption {
          type = lib.types.int;
          default = 15;
          description = "Maximum percentage of physical RAM zswap pool can consume.";
        };
      };

      config = lib.mkIf cfg.enable {
        boot.kernelParams = [
          "zswap.enabled=1"
          "zswap.compressor=${cfg.compressor}"
          "zswap.max_pool_percent=${toString cfg.maxPoolPercent}"
        ];
      };
    };
}
