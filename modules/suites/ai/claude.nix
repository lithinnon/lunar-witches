# Capability suite: Claude
{ inputs, ... }:

{
  flake.nixosModules.suite-ai-claude = { lib, pkgs, ... }: {
    home-manager.sharedModules = [
      (
        { osConfig, ... }:
        {
          home.packages = [
            inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-fhs
            pkgs.claude-code
          ];

          xdg.desktopEntries.claude-code-url-handler = {
            name = "Claude Code URL Handler";
            comment = "Handle claude-cli:// deep links for Claude Code";
            exec = "${lib.getExe pkgs.claude-code} --handle-uri %u";
            noDisplay = true;
            type = "Application";
            mimeType = [ "x-scheme-handler/claude-cli" ];
          };

          programs.claude-code = {
            enable = true;
            package = null;
            mutableSettings = true;
            settings.disableDeepLinkRegistration = "disable";
          };

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
