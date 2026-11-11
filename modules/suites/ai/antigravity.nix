# Capability suite: Google Antigravity 2.0 & CLI
{ inputs, ... }:

{
  flake.nixosModules.suite-ai-antigravity =
    { pkgs, ... }:
    let
      wrapWithKeyringBypass =
        {
          pkg,
          binName,
          extraArgs ? "",
        }:
        pkgs.symlinkJoin {
          name = "${pkg.name or binName}-keyring-bypass";
          paths = [ pkg ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            rm "$out/bin/${binName}"
            makeWrapper "${pkg}/bin/${binName}" "$out/bin/${binName}" \
              --set SSH_TTY /dev/null \
              ${extraArgs}
          '';
        };

      antigravityPkgs = inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system};

      google-antigravity = wrapWithKeyringBypass {
        pkg = antigravityPkgs.google-antigravity-no-fhs;
        binName = "antigravity";
        extraArgs = ''--add-flags "--password-store=basic"'';
      };

      google-antigravity-ide = wrapWithKeyringBypass {
        pkg = antigravityPkgs.google-antigravity-ide-no-fhs;
        binName = "antigravity-ide";
        extraArgs = ''--add-flags "--password-store=basic"'';
      };

      google-antigravity-cli = wrapWithKeyringBypass {
        pkg = antigravityPkgs.google-antigravity-cli;
        binName = "agy";
      };
    in
    {
      environment.sessionVariables = {
        AGY_CLI_HIDE_ACCOUNT_INFO = "1";
      };

      environment.systemPackages = [
        google-antigravity
        google-antigravity-ide
        google-antigravity-cli
        pkgs.mcp-nixos
      ];

      # Global Antigravity skills live in ~/.gemini/config/skills/.
      # Symlink each skill folder individually so ~/.gemini/config/skills/
      # remains a normal writable directory for local agent customizations.
      home-manager.sharedModules = [
        (
          { osConfig, ... }:
          {
            home.file = builtins.listToAttrs (
              map (name: {
                name = ".gemini/config/skills/${name}";
                value.source = "${osConfig.services.mattpocock-skills.pool}/skills/${name}";
              }) osConfig.services.mattpocock-skills.names
            );
          }
        )
      ];
    };
}
