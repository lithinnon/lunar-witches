# Capability suite: Nous Research Hermes Agent
{ inputs, ... }:

{
  flake.nixosModules.suite-ai-hermes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      sops.templates."hermes.env" = lib.mkIf (config.sops.secrets ? "tokenme_api_key") {
        owner = "nnon";
        mode = "0600";
        content = ''
          TOKENME_API_KEY=${config.sops.placeholder.tokenme_api_key}
        '';
      };

      home-manager.sharedModules = [
        inputs.hermes-agent.homeManagerModules.default
        (
          { osConfig, ... }:
          {
            programs.hermes-agent = {
              enable = lib.mkDefault true;
              desktop.enable = lib.mkDefault true;
            };

            services.hermes-agent = {
              enable = lib.mkDefault true;
              gateway.enable = false;

              backend = {
                mode = "dashboard";
                host = "127.0.0.1";
                port = 9119;
                sessionTokenFile = lib.mkIf (osConfig.sops.secrets ? "hermes_desktop_token") (
                  osConfig.sops.secrets."hermes_desktop_token".path
                );
              };

              environmentFiles = lib.optional (osConfig.sops.secrets ? "tokenme_api_key") (
                osConfig.sops.templates."hermes.env".path
              );

              settings = {
                model = {
                  default = "deepseek-ai/deepseek-v4-flash-0731";
                  provider = "custom:tokenme";
                };

                providers.tokenme = {
                  api = "https://api.tokenme.limited/api/v1/";
                  key_env = "TOKENME_API_KEY";
                };

                webapp = {
                  enabled = true;
                  host = "127.0.0.1";
                  port = 9120;
                };

                terminal = {
                  backend = "local";
                  cwd = ".";
                  timeout = 180;
                  persistent_shell = true;
                  auto_source_bashrc = true;
                };

                memory = {
                  memory_enabled = true;
                  user_profile_enabled = true;
                };

                display = {
                  compact = false;
                  interface = "cli";
                  cli_layout = "modern";
                  show_reasoning = true;
                  reasoning_style = "code";
                  inline_diffs = true;
                };
              };

              extraPackages = with pkgs; [
                git
                ripgrep
                ffmpeg
              ];
            };
          }
        )
      ];
    };
}
