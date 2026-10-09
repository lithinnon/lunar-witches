# In-tree derivation for beellama.cpp (custom llama.cpp fork with ROCm & HRX support)
# Wraps the local build-hrx binaries into standard Nix package outputs with HRX runpath
{
  lib,
  stdenvNoCC,
  # Path to the compiled beellama.cpp build directory
  beellamaDir ? "/home/nnon/Projects/github.com/lithinnon/beellama.cpp/build-hrx",
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
        echo "Run 'build-hrx.sh' in ${beellamaDir}/.. to compile beellama.cpp" >&2
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
