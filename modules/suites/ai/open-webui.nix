# Capability suite: Open WebUI
{ ... }:

{
  flake.nixosModules.suite-ai-open-webui =
    { lib, ... }:
    {
      services.open-webui = {
        enable = true;
        port = 11111;
        environment = {
          BRAVE_SEARCH_API_KEY = "";

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

      # On-demand execution (toggled via Service Deck, not started at boot)
      systemd.services.open-webui = {
        wantedBy = lib.mkForce [ ];
        serviceConfig = {
          Nice = 19;
          CPUSchedulingPolicy = "batch";
          IOSchedulingClass = "idle";
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
