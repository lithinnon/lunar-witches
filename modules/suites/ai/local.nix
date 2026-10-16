# Capability suite: Local LLM inference engines (beellama / llama.cpp on ROCm & HRX)
#
# Manages local inference infrastructure:
#   * beellama (custom llama.cpp fork with ROCm/HRX support)
#   * llama-swap user service running on 127.0.0.1:8080
#   * On-demand model lifecycle (spawning llama-server per model with TTL)
#   * hf CLI (huggingface-hub) for pulling GGUF models
{ ... }:

{
  flake.nixosModules.suite-ai-local =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.suites.ai.local;

      # Nix value → YAML converter (pkgs.formats.yaml standard, remarshal-
      # backed): the llama-swap config below is written as a Nix attrset and
      # rendered to YAML at build time.
      llamaSwapFormat = pkgs.formats.yaml { };

      # Reusable command generator for llama-server instances.
      # Extracts redundant hardware, cache tier, batching, and reasoning flags
      # shared across models on the Strix Halo Radeon 8060S (ROCm gfx1151).
      # Supports symmetric (`cacheTypeKV`) or asymmetric (`cacheTypeK` / `cacheTypeV`)
      # KV cache quantization (e.g. snc4 key + snc8 value).
      mkServerCmd =
        {
          hfRepo,
          ctxSize,
          cacheTypeKV ? null,
          cacheTypeK ? (if cacheTypeKV != null then cacheTypeKV else "snc8"),
          cacheTypeV ? (if cacheTypeKV != null then cacheTypeKV else "snc8"),
          kvTailTokens,
          reasoningPreserve,
          extraFlags ? [ ],
        }:
        ''
          ${cfg.package}/bin/llama-server \
              --ctx-size ${toString ctxSize} \
              --batch-size 2048 \
              --ubatch-size 512 \
              --flash-attn on \
              --cache-type-k ${cacheTypeK} \
              --cache-type-v ${cacheTypeV} \
              --kv-tail-tokens ${toString kvTailTokens} \
              --kv-tail-type bf16 \
              --cache-ram 0 \
              --cache-disk 16384 \
              --device ROCm0 \
              --n-gpu-layers all \
              --hf-repo ${hfRepo} \
              --no-mmproj \
              --port ''${PORT} \
              --no-webui \
              --reasoning-format deepseek \
              --reasoning on \
              --reasoning-loop-check-interval 32 \
              --reasoning-loop-interventions 1 \
              ${if reasoningPreserve then "--reasoning-preserve" else "--no-reasoning-preserve"} \
              --repeat-last-n 128 \
              ${lib.concatStringsSep " \\\n    " extraFlags}
        '';
    in
    {
      options.suites.ai.local = {
        enable = lib.mkEnableOption "Local LLM inference suite (beellama with ROCm support)" // {
          default = true;
        };

        backend = lib.mkOption {
          type = lib.types.enum [
            "rocm"
            "hrx"
          ];
          default = "rocm";
          description = "ROCm runtime backend for beellama: 'rocm' (native ROCm HIP) or 'hrx' (HIP Runtime Extended).";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.beellama.override { inherit (cfg) backend; };
          description = "Configured beellama package.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          cfg.package
          # HF Hub client (`hf` CLI) for pulling GGUF models and datasets
          pkgs.python314Packages.huggingface-hub
          # On-demand model swap proxy: manages llama-server instances per model
          pkgs.llama-swap
        ];

        # llama-swap config, consumed at $XDG_CONFIG_HOME/llama-swap.yml.
        # Written as a Nix attrset and rendered to YAML via pkgs.formats.yaml;
        # schema notes live as comments next to the values they describe.
        home-manager.sharedModules = [
          {
            xdg.configFile."llama-swap.yml".source = llamaSwapFormat.generate "llama-swap.yml" (
              # Schema: config-schema.json @ github.com/mostlygeek/llama-swap —
              # only `models` is required; every other top-level key has a
              # default (healthCheckTimeout=120, globalTTL=0, logLevel=info,
              # startPort=5800 for the ${PORT} macro, proxy already
              # http://localhost:${PORT}, checkEndpoint=/health).
              #   * model ID = the `model` value clients send in API requests
              #   * ttl is INTEGER SECONDS (-1 = global default, 0 = never)
              {
                models = {
                  "creative/boulesis-v2.1-headtune" = {
                    ttl = 1200; # 20 minutes
                    cmd = mkServerCmd {
                      hfRepo = "mradermacher/Boulesis-v2.1-26B-A4B-HeadTune-i1-GGUF:IQ4_XS";
                      ctxSize = 65536;
                      cacheTypeKV = "snc8";
                      kvTailTokens = 1024;
                      reasoningPreserve = false;
                      extraFlags = [
                        "--reasoning-budget 2304"
                        ''--reasoning-budget-message " ... reasoning budget exceeded, need to answer.\n"''
                        "--temp 1.00"
                        "--top-k 64"
                        "--repeat-penalty 1.06"
                        "--dry-multiplier 0.80"
                        "--dry-penalty-last-n 256"
                      ];
                    };
                  };
                  "agentic/lfm2.5-24b-a2b" = {
                    ttl = 600; # 10 minutes
                    cmd = mkServerCmd {
                      hfRepo = "LiquidAI/LFM2.5-24B-A2B-GGUF:QAD-Q4_0";
                      ctxSize = 196608; # 192k
                      cacheTypeK = "snc4";
                      cacheTypeV = "snc4";
                      kvTailTokens = 256;
                      reasoningPreserve = true;
                      extraFlags = [
                        "--jinja"
                        "--temp 0.10"
                        "--top-k 50"
                        "--repeat-penalty 1.05"
                      ];
                    };
                  };
                };
              }
            );

            # User-level proxy service. Loopback-only: local clients (SillyTavern,
            # coding agents, CLI) reach it on 127.0.0.1:8080.
            systemd.user.services.llama-swap = {
              Unit = {
                Description = "llama-swap — on-demand model swapping proxy for llama.cpp";
              };
              Service = {
                Type = "simple";
                ExecStart = "${pkgs.llama-swap}/bin/llama-swap -config %h/.config/llama-swap.yml -listen 127.0.0.1:8080";
                Restart = "on-failure";
                RestartSec = 2;
              };
              Install = {
                WantedBy = [ "default.target" ];
              };
            };
          }
        ];
      };
    };
}
