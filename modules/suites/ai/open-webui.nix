# Capability suite: Open WebUI
{ ... }:

{
  flake.nixosModules.suite-ai-open-webui =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.open-webui = {
        enable = true;
        port = 11112; # Internal backend port proxied from socket 11111
        environmentFile = lib.mkIf (
          config.sops.secrets ? "brave_search_api_key"
        ) config.sops.templates."open-webui.env".path;
        environment = {
          # Bypass local RAG / SentenceTransformers / PyTorch preloading
          RAG_EMBEDDING_MODEL_AUTO_UPDATE = "False";

          # Silence 1-second SQLite polling loops & time-based schedulers
          TIMER_POLL_INTERVAL = "86400";
          SCHEDULER_POLL_INTERVAL = "86400";

          # Silence outbound telemetry and background pings
          ENABLE_ADMIN_ANALYTICS = "False";
          SCARF_NO_ANALYTICS = "True";
          DO_NOT_TRACK = "True";
          ANONYMIZED_TELEMETRY = "False";
        };
      };

      sops.templates."open-webui.env" =
        lib.mkIf (config.services.open-webui.enable && config.sops.secrets ? "brave_search_api_key")
          {
            content = ''
              BRAVE_SEARCH_API_KEY=${config.sops.placeholder.brave_search_api_key}
            '';
          };

      # Socket activation on port 11111 with 10-minute idle auto-shutdown
      systemd.sockets.open-webui-proxy = {
        description = "Open WebUI Socket";
        wantedBy = [ "sockets.target" ];
        listenStreams = [
          "127.0.0.1:11111"
          "[::1]:11111"
        ];
      };

      systemd.services.open-webui-proxy = {
        description = "Open WebUI Socket Proxy (10m Idle Auto-Stop)";
        requires = [ "open-webui.service" ];
        after = [ "open-webui.service" ];
        bindsTo = [ "open-webui.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=10m 127.0.0.1:11112";
          DynamicUser = true;
          PrivateTmp = true;
        };
      };

      # On-demand execution bound to socket proxy lifecycle
      systemd.services.open-webui = {
        wantedBy = lib.mkForce [ ];
        bindsTo = [ "open-webui-proxy.service" ];
        serviceConfig = {
          Nice = 19;
          CPUSchedulingPolicy = "batch";
          IOSchedulingClass = "idle";
          ExecStartPost = "${pkgs.writeShellScript "wait-for-open-webui" ''
            for i in $(seq 1 300); do
              if ${pkgs.curl}/bin/curl -s -f http://127.0.0.1:11112/health >/dev/null 2>&1; then
                exit 0
              fi
              sleep 0.2
            done
            exit 1
          ''}";
        };
      };

      # This overlay explicitly drops 'mcp-types' from the upstream 2.x dependency list
      # and forces the environment to resolve the older, monolithic 1.30.0 version of 'mcp'
      # and all its 1.x runtime requirements (jsonschema, pyjwt, etc.) to bypass the missing
      # 'streamable_http' module crash that currently breaks 'python3.14-posthog' and 'open-webui'.
      nixpkgs.overlays = [
        (final: prev: {
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (
              python-final: python-prev:
              let
                mcp-downgraded = python-prev.mcp.overridePythonAttrs (old: rec {
                  version = "1.30.0";
                  src = prev.fetchPypi {
                    pname = "mcp";
                    inherit version;
                    hash = "sha256-RFQUYl/OXClfqlBbsRus7OZhq29AKNV8k121eCC3o+Q=";
                  };

                  dependencies = with python-prev; [
                    anyio
                    httpx
                    httpx-sse
                    jsonschema
                    pydantic
                    pydantic-settings
                    pyjwt
                    python-multipart
                    sse-starlette
                    uvicorn
                  ];

                  doCheck = false;
                });
              in
              {
                posthog = python-prev.posthog.overridePythonAttrs (old: {
                  meta = (old.meta or { }) // {
                    broken = false;
                  };
                  doCheck = false;
                });

                mcp = mcp-downgraded;
                mcp-types = mcp-downgraded;
              }
            )
          ];
        })
      ];
    };
}
