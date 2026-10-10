# Capability suite: Local LLM inference engines (beellama / llama.cpp on ROCm & HRX)
{ ... }:

{
  flake.nixosModules.suite-ai-local =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.suites.ai.local;
    in
    {
      options.suites.ai.local = {
        enable = lib.mkEnableOption "Local LLM inference suite (beellama with ROCm support)" // {
          default = true;
        };

        backend = lib.mkOption {
          type = lib.types.enum [ "rocm" "hrx" ];
          default = "rocm";
          description = "ROCm runtime backend for beellama: 'rocm' (native ROCm HIP) or 'hrx' (HIP Runtime Extended).";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.beellama.override { inherit (cfg) backend; };
          description = "Configured beellama package.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          cfg.package
        ];
      };
    };
}
