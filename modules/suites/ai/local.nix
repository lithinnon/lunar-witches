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
        enable = lib.mkEnableOption "Local LLM inference suite (beellama with ROCm & HRX support)" // {
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.beellama
        ];
      };
    };
}
