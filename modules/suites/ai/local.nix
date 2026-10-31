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
      # Provides intelligent, production-tuned defaults for agentic coding,
      # anti-looping guards, DRY sampling, and asymmetric SNC KV cache.
      mkServerCmd =
        {
          hfRepo ? null,
          model ? null,
          mmproj ? null,
          chatTemplate ? null,
          ctxSize ? 65536,
          cacheTypeKV ? null,
          cacheTypeK ? (if cacheTypeKV != null then cacheTypeKV else "snc4"),
          cacheTypeV ? (if cacheTypeKV != null then cacheTypeKV else "snc8"),
          kvTailTokens ? 1024,
          reasoning ? true,
          reasoningFormat ? "deepseek",
          reasoningPreserve ? false,
          reasoningBudget ? 4096,
          reasoningBudgetMessage ? " ... reasoning budget exceeded, need to answer.\\n",
          reasoningLoopGuard ? "force-close",
          reasoningLoopCheckInterval ? 32,
          reasoningLoopInterventions ? 1,
          temp ? 0.70,
          topK ? null,
          topP ? 0.90,
          minP ? 0.05,
          repeatLastN ? 256,
          repeatPenalty ? 1.02,
          dryMultiplier ? 0.50,
          dryBase ? 1.75,
          dryAllowedLength ? 5,
          dryPenaltyLastN ? 512,
          jinja ? false,
          specType ? null,
          parallel ? 1,
          cacheRam ? null,
          cacheDisk ? null,
          extraFlags ? [ ],
          batchSize ? 2048,
          ubatchSize ? 512,
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

          dryFlags =
            if dryMultiplier != null && dryMultiplier > 0 then
              [
                "--dry-multiplier ${toString dryMultiplier}"
                "--dry-base ${toString dryBase}"
                "--dry-allowed-length ${toString dryAllowedLength}"
                "--dry-penalty-last-n ${toString dryPenaltyLastN}"
                "--dry-sequence-breaker none"
              ]
            else
              [ ];

          reasoningFlags =
            if reasoning then
              lib.filter (f: f != null) [
                (if reasoningFormat != null then "--reasoning-format ${reasoningFormat}" else null)
                "--reasoning on"
                (if reasoningLoopGuard != null then "--reasoning-loop-guard ${reasoningLoopGuard}" else null)
                (
                  if reasoningLoopCheckInterval != null then
                    "--reasoning-loop-check-interval ${toString reasoningLoopCheckInterval}"
                  else
                    null
                )
                (
                  if reasoningLoopInterventions != null then
                    "--reasoning-loop-interventions ${toString reasoningLoopInterventions}"
                  else
                    null
                )
                (if reasoningBudget != null then "--reasoning-budget ${toString reasoningBudget}" else null)
                (
                  if reasoningBudget != null && reasoningBudgetMessage != null then
                    ''--reasoning-budget-message "${reasoningBudgetMessage}"''
                  else
                    null
                )
                (if reasoningPreserve then "--reasoning-preserve" else "--no-reasoning-preserve")
              ]
            else
              [ "--reasoning off" ];

          samplingFlags =
            lib.filter (f: f != null) [
              (if temp != null then "--temp ${toString temp}" else null)
              (if topK != null then "--top-k ${toString topK}" else null)
              (if topP != null then "--top-p ${toString topP}" else null)
              (if minP != null then "--min-p ${toString minP}" else null)
              (if repeatPenalty != null then "--repeat-penalty ${toString repeatPenalty}" else null)
              (if repeatLastN != null then "--repeat-last-n ${toString repeatLastN}" else null)
            ]
            ++ dryFlags;

          featureFlags = lib.filter (f: f != null) [
            (if jinja then "--jinja" else null)
            (if specType != null then "--spec-type ${specType}" else null)
          ];

          serverFlags =
            lib.filter (f: f != null) [
              modelFlag
              mmprojFlag
              chatTemplateFlag
              "--port \${PORT}"
              "--no-webui"
            ]
            ++ reasoningFlags
            ++ samplingFlags
            ++ featureFlags
            ++ extraFlags;
        in
        ''
          ${cfg.package}/bin/llama-server \
              --parallel ${toString parallel} \
              --ctx-size ${toString ctxSize} \
              --batch-size ${toString batchSize} \
              --ubatch-size ${toString ubatchSize} \
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
                      reasoningPreserve = true; # Maintain persona consistency in creative RP
                      reasoningBudget = 2304;
                      temp = 1.00;
                      topK = 64;
                      repeatPenalty = 1.06;
                      dryPenaltyLastN = 256;
                      extraFlags = [ "-cram 1228" ];
                    };
                  };
                  "reasoning/qwen3.8-26b-a4b" = {
                    ttl = 1200; # 20 minutes
                    cmd = mkServerCmd {
                      model = "/home/nnon/Projects/github.com/lithinnon/qwen3.8-26b-a4b/Qwen3.8-26B-A4B.gguf";
                      chatTemplate = "/home/nnon/Projects/github.com/lithinnon/qwen3.8-26b-a4b/chat_template.jinja";
                      ctxSize = 131072; # 128k context
                      kvTailTokens = 512;
                      jinja = true;
                      specType = "draft-mtp";
                      # Inherits universal agent defaults:
                      # reasoningBudget = 4096 (with budget exceeded message)
                      # reasoningPreserve = false (strips intermediate thoughts)
                      # reasoningLoopGuard = "force-close"
                      # cacheTypeK = "snc4", cacheTypeV = "snc8"
                      # temp = 0.70, minP = 0.05, topP = 0.90, repeatPenalty = 1.08, repeatLastN = 512
                      # dryMultiplier = 0.80, dryPenaltyLastN = 512
                    };
                  };
                  "unleashed/gemma-4-26B-A4B-it" = {
                    ttl = 600; # 10 minutes
                    cmd = mkServerCmd {
                      hfRepo = "llmfan46/gemma-4-26B-A4B-it-uncensored-heretic-GGUF:Q4_K_S";
                      mmproj = "auto";
                      cacheTypeKV = "snc4";
                      kvTailTokens = 1024;
                      temp = 1.0;
                      topK = 64;
                      ubatchSize = 1024;
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
                  agents = {
                    swap = true;
                    exclusive = false;
                    members = [
                      "creative/boulesis-v2.1-headtune"
                      "reasoning/qwen3.8-26b-a4b"
                      "unleashed/gemma-4-26B-A4B-it"
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
