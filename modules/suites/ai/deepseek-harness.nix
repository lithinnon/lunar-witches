# Capability suite: DeepSeek Harness (dsh)
{ ... }:

{
  flake.nixosModules.suite-ai-deepseek-harness =
    { lib, pkgs, ... }:
    let
      dshWrapped = pkgs.symlinkJoin {
        name = "deepseek-harness-xdg-${pkgs.deepseek-harness.version}";
        paths = [ pkgs.deepseek-harness ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/dsh \
            --run 'export DSH_HOME="''${DSH_HOME:-$HOME/.config/dsh}"'
        '';
      };

      dshOpen = pkgs.writeShellApplication {
        name = "dsh-open";
        runtimeInputs = [
          pkgs.systemd
          pkgs.gnugrep
          pkgs.coreutils
          pkgs.xdg-utils
        ];
        text = ''
          if ! systemctl --user is-active --quiet deepseek-harness.service; then
            echo "Starting deepseek-harness.service..."
            systemctl --user start deepseek-harness.service
            for _ in $(seq 1 30); do
              if systemctl --user is-active --quiet deepseek-harness.service; then
                break
              fi
              sleep 0.2
            done
          fi

          url=""
          for _ in $(seq 1 30); do
            url=$(journalctl --user -u deepseek-harness.service -n 50 --no-pager 2>/dev/null | grep -o 'http://127.0.0.1:[0-9]\+/?token=[^[:space:]]*' | tail -n 1 || true)
            if [ -n "$url" ]; then
              break
            fi
            sleep 0.2
          done

          if [ -z "$url" ]; then
            url="http://127.0.0.1:3080"
          fi

          echo "Opening DeepSeek Harness: $url"
          exec xdg-open "$url"
        '';
      };
    in
    {
      home-manager.sharedModules = [
        (
          { config, ... }:
          {
            home.packages = [
              dshWrapped
              dshOpen
            ];

            home.sessionVariables = {
              DSH_HOME = "${config.xdg.configHome}/dsh";
            };

            xdg.desktopEntries.deepseek-harness = {
              name = "DeepSeek Harness";
              comment = "DeepSeek Harness Web Console";
              exec = "${dshOpen}/bin/dsh-open";
              icon = "${pkgs.deepseek-harness}/libexec/dsh/apps/desktop/resources/icon.svg";
              terminal = false;
              type = "Application";
              categories = [
                "Development"
                "Network"
              ];
            };

            systemd.user.services.deepseek-harness = {
              Unit = {
                Documentation = [ "https://github.com/deepseek-ai/deepseek-harness" ];
                After = [ "network.target" ];
              };

              Service = {
                Type = "simple";
                ExecStart = "${dshWrapped}/bin/dsh --profile web --no-open --host 127.0.0.1 --port 3080";
                Restart = "on-failure";
                RestartSec = "5s";
                Environment = [
                  "DSH_HOME=${config.xdg.configHome}/dsh"
                  "PATH=${
                    lib.makeBinPath [
                      pkgs.git
                      pkgs.ripgrep
                      pkgs.coreutils
                    ]
                  }:/run/current-system/sw/bin"
                ];
              };

              Install = {
                WantedBy = [ "default.target" ];
              };
            };
          }
        )
      ];
    };
}
