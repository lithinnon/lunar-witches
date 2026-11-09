# Shared wiring: expose the mattpocock skill pool on the NixOS config so every
# AI suite (pi, claude, antigravity) can point at the same read-only store
# path instead of each maintaining its own copy or symlink farm.
{ inputs, ... }:

{
  flake.nixosModules.suite-ai-mattpocock-skills =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      pool = pkgs.callPackage ../../../pkgs/mattpocock-skills {
        src = inputs.mattpocock-skills;
      };

      # Skill folder names, derived from the *source* (a pure store path during
      # eval), not from the built derivation output, so nothing has to be
      # built to read this list.
      names = builtins.concatLists (
        map
          (
            bucket:
            let
              entries = builtins.readDir "${inputs.mattpocock-skills}/skills/${bucket}";
            in
            builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries)
          )
          [
            "engineering"
            "productivity"
          ]
      );
    in
    {
      options.services.mattpocock-skills = {
        pool = lib.mkOption {
          type = lib.types.path;
          description = "Flattened read-only mattpocock skill pool (skills/<name>/SKILL.md).";
        };
        names = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Skill folder names in the pool.";
        };
      };

      config.services.mattpocock-skills = {
        inherit pool names;
      };
    };
}
