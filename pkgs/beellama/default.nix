# In-tree derivation for beellama.cpp (custom llama.cpp fork with ROCm & HRX support)
# Wraps the local build directory binaries into standard Nix package outputs
{
  lib,
  stdenvNoCC,
  # Runtime backend: "rocm" (standard TheRock HIP) or "hrx" (HIP Runtime Extended)
  backend ? "rocm",
  # Path to the compiled beellama.cpp build directory
  beellamaDir ?
    if backend == "hrx" then
      "/home/nnon/Projects/github.com/lithinnon/triellama.cpp/build-hrx"
    else
      "/home/nnon/Projects/github.com/lithinnon/triellama.cpp/build",
}:

let
  binaries = [
    "llama"
    "llama-batched-bench"
    "llama-bench"
    "llama-cli"
    "llama-completion"
    "llama-cvector-generator"
    "llama-export-lora"
    "llama-fit-params"
    "llama-gemma3-cli"
    "llama-gguf-split"
    "llama-imatrix"
    "llama-llava-cli"
    "llama-minicpmv-cli"
    "llama-mtmd-cli"
    "llama-mtmd-debug"
    "llama-perplexity"
    "llama-quantize"
    "llama-qwen2vl-cli"
    "llama-results"
    "llama-server"
    "llama-tokenize"
    "llama-tts"
  ];
  buildScript = if backend == "hrx" then "build-hrx.sh" else "build.sh";
in
stdenvNoCC.mkDerivation {
  pname = "beellama";
  version = "0.4.7";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    ${lib.concatMapStringsSep "\n" (bin: ''
      cat << 'EOF' > "$out/bin/${bin}"
      #!/usr/bin/env bash
      export LD_LIBRARY_PATH="${beellamaDir}/lib:${beellamaDir}/bin''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      if [ ! -x "${beellamaDir}/bin/${bin}" ]; then
        echo "Error: ${bin} not found at ${beellamaDir}/bin/${bin}" >&2
        echo "Run '${buildScript}' in ${beellamaDir}/.. to compile triellama.cpp" >&2
        exit 1
      fi
      exec "${beellamaDir}/bin/${bin}" "$@"
      EOF
      chmod +x "$out/bin/${bin}"
    '') binaries}
  '';

  meta = with lib; {
    description = "beellama.cpp — custom llama.cpp fork for Strix Halo with ROCm/HRX acceleration";
    homepage = "https://github.com/lithinnon/beellama.cpp";
    platforms = platforms.linux;
    mainProgram = "llama-server";
  };
}
