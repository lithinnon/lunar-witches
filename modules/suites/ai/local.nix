# Capability suite: Local LLM inference engines (triellama / llama.cpp on ROCm & HRX)
#
# Manages local inference infrastructure:
#   * triellama (custom llama.cpp fork with ROCm/HRX support)
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
          hfRepo ? null,
          model ? null,
          mmproj ? null,
          chatTemplate ? null,
          ctxSize,
          cacheTypeKV ? null,
          cacheTypeK ? (if cacheTypeKV != null then cacheTypeKV else "snc8"),
          cacheTypeV ? (if cacheTypeKV != null then cacheTypeKV else "snc8"),
          kvTailTokens,
          reasoningPreserve,
          parallel ? 1,
          cacheRam ? null,
          cacheDisk ? null,
          extraFlags ? [ ],
        }:
        let
          hasCustomCacheRam =
            cacheRam != null
            || lib.any (f: lib.hasPrefix "-cram" f || lib.hasPrefix "--cache-ram" f) extraFlags;
          hasCustomCacheDisk =
            cacheDisk != null
            || lib.any (f: lib.hasPrefix "-cdisk" f || lib.hasPrefix "--cache-disk" f) extraFlags;

          # Radix cache tier limits: multimodal projectors (mmproj) populate multimodal tokens
          # (has_mtmd = true), which triellama's disk eviction tier cannot serialize without asserting.
          # For multimodal models, reserve 2 GiB RAM cache and disable disk spill by default.
          effectiveCacheRam =
            if cacheRam != null then
              cacheRam
            else if hasCustomCacheRam then
              null
            else if mmproj != null then
              2048
            else
              0;
          effectiveCacheDisk =
            if cacheDisk != null then
              cacheDisk
            else if hasCustomCacheDisk then
              null
            else if mmproj != null then
              0
            else
              16384;

          modelFlag =
            if model != null then
              "--model ${model}"
            else if hfRepo != null then
              "--hf-repo ${hfRepo}"
            else
              throw "mkServerCmd requires either 'model' or 'hfRepo'";
          mmprojFlag =
            if mmproj == "auto" then
              "--mmproj-auto"
            else if mmproj != null then
              "--mmproj ${mmproj}"
            else
              "--no-mmproj";
          chatTemplateFlag = if chatTemplate != null then "--chat-template-file ${chatTemplate}" else null;
          serverFlags =
            lib.filter (f: f != null) [
              modelFlag
              mmprojFlag
              chatTemplateFlag
              "--port \${PORT}"
              "--no-webui"
              "--reasoning-format deepseek"
              "--reasoning on"
              "--reasoning-loop-guard force-close"
              "--reasoning-loop-check-interval 32"
              "--reasoning-loop-interventions 1"
              (if reasoningPreserve then "--reasoning-preserve" else "--no-reasoning-preserve")
              "--repeat-last-n 512"
            ]
            ++ extraFlags;
        in
        ''
          ${cfg.package}/bin/llama-server \
              --parallel ${toString parallel} \
              --ctx-size ${toString ctxSize} \
              --batch-size 2048 \
              --ubatch-size 512 \
              --flash-attn on \
              --cache-type-k ${cacheTypeK} \
              --cache-type-v ${cacheTypeV} \
              --kv-tail-tokens ${toString kvTailTokens} \
              --kv-tail-type bf16 \
              ${
                lib.optionalString (effectiveCacheRam != null) "--cache-ram ${toString effectiveCacheRam} \\\n    "
              }${
                lib.optionalString (
                  effectiveCacheDisk != null
                ) "--cache-disk ${toString effectiveCacheDisk} \\\n    "
              }--device ROCm0 \
              --n-gpu-layers all \
              ${lib.concatStringsSep " \\\n    " serverFlags}
        '';
    in
    {
      options.suites.ai.local = {
        enable = lib.mkEnableOption "Local LLM inference suite (triellama with ROCm support)" // {
          default = true;
        };

        backend = lib.mkOption {
          type = lib.types.enum [
            "rocm"
            "hrx"
          ];
          default = "rocm";
          description = "ROCm runtime backend for triellama: 'rocm' (native ROCm HIP) or 'hrx' (HIP Runtime Extended).";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.triellama.override { inherit (cfg) backend; };
          description = "Configured triellama package.";
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
                      cacheTypeK = "snc4";
                      cacheTypeV = "snc8";
                      kvTailTokens = 1024;
                      reasoningPreserve = true;
                      extraFlags = [
                        "-cram 1228"
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
                  "reasoning/qwen3.8-26b-a4b" = {
                    ttl = 1200; # 20 minutes
                    cmd = mkServerCmd {
                      model = "/home/nnon/Projects/github.com/lithinnon/qwen3.8-26b-a4b/Qwen3.8-26B-A4B.gguf";
                      # mmproj = "/home/nnon/Projects/github.com/lithinnon/qwen3.8-26b-a4b/mmproj-Qwen3.8-26B-A4B.gguf";
                      chatTemplate = "/home/nnon/Projects/github.com/lithinnon/qwen3.8-26b-a4b/chat_template.jinja";
                      ctxSize = 131072; # 128k
                      cacheTypeK = "snc4";
                      cacheTypeV = "snc8";
                      kvTailTokens = 512;
                      reasoningPreserve = false;
                      extraFlags = [
                        "--jinja"
                        "--spec-type draft-mtp"
                        "--temp 0.70"
                        "--min-p 0.05"
                        "--top-p 0.90"
                        "--repeat-penalty 1.08"
                        "--dry-multiplier 0.80"
                        "--dry-base 1.75"
                        "--dry-allowed-length 2"
                        "--dry-penalty-last-n 512"
                        "--reasoning-budget 4096"
                        ''--reasoning-budget-message " ... reasoning budget exceeded, need to answer.\n"''
                      ];
                    };
                  };
                  "general/gemma-4-12B-it" = {
                    ttl = 600; # 10 minutes
                    cmd = mkServerCmd {
                      hfRepo = "unsloth/gemma-4-12B-it-qat-GGUF:UD-Q4_K_XL";
                      mmproj = "auto";
                      ctxSize = 65536; # 64k
                      cacheTypeKV = "snc8";
                      kvTailTokens = 1024;
                      reasoningPreserve = false;
                      extraFlags = [
                        "--spec-type draft-mtp"
                        "--temp 1.0"
                        "--top-k 64"
                      ];
                    };
                  };
                  "vector/embeddinggemma-2" = {
                    ttl = 300; # 5 minutes
                    cmd = ''
                      ${cfg.package}/bin/llama-server \
                          --hf-repo unsloth/embeddinggemma-2-GGUF:BF16 \
                          --embedding \
                          --pooling mean \
                          --embd-normalize 2 \
                          --ctx-size 8192 \
                          --batch-size 8192 \
                          --ubatch-size 8192 \
                          --flash-attn on \
                          --threads 12 \
                          --n-gpu-layers 0 \
                          --no-mmproj \
                          --port ''${PORT} \
                          --no-webui
                    '';
                  };
                };

                groups = {
                  chat = {
                    swap = true;
                    exclusive = false;
                    members = [
                      "creative/boulesis-v2.1-headtune"
                      "reasoning/qwen3.8-26b-a4b"
                      "general/gemma-4-12B-it"
                    ];
                  };
                  embeddings = {
                    swap = false;
                    exclusive = false;
                    persistent = false;
                    members = [
                      "vector/embeddinggemma-2"
                    ];
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
