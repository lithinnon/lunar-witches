# Capability suite: Open WebUI
{ ... }:

{
  flake.nixosModules.suite-ai-open-webui = { ... }: {
    services.open-webui = {
      enable = true;
      port = 11111;
      environment = {
        ENABLE_INITIAL_ADMIN_SIGNUP = "True";
        ENABLE_WEB_SEARCH = "True";
        WEB_SEARCH_ENGINE = "brave_llm_context";
        BRAVE_SEARCH_API_KEY = "";
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
