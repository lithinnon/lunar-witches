# Capability suite: ROCm (TheRock) AI & GPU Diagnostics and Runtime Environment
{ lib, ... }:

{
  flake.nixosModules.suite-ai-rocm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.suites.ai.rocm;
      rocmPkg =
        if cfg.gfx != null then
          pkgs.rocm-therock {
            gfx = cfg.gfx;
            inherit (cfg) version;
          }
        else
          null;
    in
    {
      options.suites.ai.rocm = {
        enable = lib.mkEnableOption "ROCm (TheRock) AI and GPU compute suite";

        gfx = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "gfx1151";
          description = "Target GPU architecture for ROCm (e.g. 'gfx1151', 'gfx1100', 'multiarch'). Must be explicitly specified.";
        };

        version = lib.mkOption {
          type = lib.types.str;
          default = "10.1.0";
          description = "ROCm (TheRock) release version.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.gfx != null;
            message = "suites.ai.rocm.gfx must be explicitly set when suites.ai.rocm is enabled.";
          }
        ];

        # System packages: expose only lightweight diagnostic utilities on global $PATH.
        # Compilers (hipcc, amdclang++) are strictly confined to developer shells (amd-dev).
        environment.systemPackages = lib.optional (rocmPkg != null) (
          pkgs.runCommand "rocm-diagnostics" { } ''
            mkdir -p $out/bin
            for bin in rocminfo amd-smi rocm_agent_enumerator; do
              if [ -e "${rocmPkg}/bin/$bin" ]; then
                ln -s "${rocmPkg}/bin/$bin" "$out/bin/$bin"
              fi
            done
          ''
        );

        # Runtime dynamic libraries for unpatched binaries & external runners via nix-ld
        programs.nix-ld.libraries = lib.optional (rocmPkg != null) rocmPkg;
      };
    };
}
