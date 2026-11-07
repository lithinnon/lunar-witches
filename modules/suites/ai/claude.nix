# Capability suite: Claude
{ inputs, ... }:

{
  flake.nixosModules.suite-ai-claude = { pkgs, ... }: {
    home-manager.sharedModules = [
      {
        home.packages = [
          inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-fhs
          pkgs.claude-code
        ];
      }
      (
        { lib, osConfig, ... }:
        {
          # Merge-per-skill symlinks into ~/.claude/skills so Claude's own
          # `synced/` dir is preserved. Each links back to the read-only pool.
          home.file = builtins.listToAttrs (
            map (name: {
              name = ".claude/skills/${name}";
              value.source = "${osConfig.services.mattpocock-skills.pool}/skills/${name}";
            }) osConfig.services.mattpocock-skills.names
          );
        }
      )
    ];
  };
}
