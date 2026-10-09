{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, zlib
, numactl
, libdrm
, elfutils
, libtool
, glibc
, gcc
, gfx ? throw "pkgs.rocm-therock: 'gfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'multiarch')."
, version ? "10.1.0"
, hash ? null
}:

let
  # Mapping from gfx to upstream TheRock tarball target identifier
  tarballTargets = {
    # AMD APUs (Strix Halo / Strix Point / Kraken Point / Mendocino)
    "gfx1151" = { name = "gfx1151"; hash = "sha256-UN65kwNbwvalq6Xj3o1HbYxRKi7sLL/VqladceC4szc="; };
    "gfx1150" = { name = "gfx1150"; hash = "sha256-UV3xFwchZoQnpgKAcENxnlmTcQmGPguqdWaHXp/M8HA="; };
    "gfx1152" = { name = "gfx1152"; hash = "sha256-zu2HFK2z23iF9tJXhAYGh/t3LT2e0kSXec52NtiIJ8A="; };
    "gfx1153" = { name = "gfx1153"; hash = "sha256-oygvOy6Aa/nXN5kgoCBwp62bAZwnHgg//ZpTES1Bwno="; };

    # RDNA 3 dGPUs & APUs (7900 XTX, 7800 XT, 7600, 7840U, etc.)
    "gfx1100" = { name = "gfx110X-all"; hash = "sha256-D12hJGAXhqsbn9vM/Kg7kxquO/fanGBAed2y3Ppl1xc="; };
    "gfx1101" = { name = "gfx110X-all"; hash = "sha256-D12hJGAXhqsbn9vM/Kg7kxquO/fanGBAed2y3Ppl1xc="; };
    "gfx1102" = { name = "gfx110X-all"; hash = "sha256-D12hJGAXhqsbn9vM/Kg7kxquO/fanGBAed2y3Ppl1xc="; };
    "gfx1103" = { name = "gfx110X-all"; hash = "sha256-D12hJGAXhqsbn9vM/Kg7kxquO/fanGBAed2y3Ppl1xc="; };
    "gfx110X-all" = { name = "gfx110X-all"; hash = "sha256-D12hJGAXhqsbn9vM/Kg7kxquO/fanGBAed2y3Ppl1xc="; };

    # RDNA 2 dGPUs & APUs (6900 XT, 6800, 6700, 680M, etc.)
    "gfx1030" = { name = "gfx103X-all"; hash = "sha256-n88XZEaLx10kl7CwkWX+9vPgvAGuwfx2r3yK/Y+VTR4="; };
    "gfx1031" = { name = "gfx103X-all"; hash = "sha256-n88XZEaLx10kl7CwkWX+9vPgvAGuwfx2r3yK/Y+VTR4="; };
    "gfx1032" = { name = "gfx103X-all"; hash = "sha256-n88XZEaLx10kl7CwkWX+9vPgvAGuwfx2r3yK/Y+VTR4="; };
    "gfx1035" = { name = "gfx103X-all"; hash = "sha256-n88XZEaLx10kl7CwkWX+9vPgvAGuwfx2r3yK/Y+VTR4="; };
    "gfx103X-all" = { name = "gfx103X-all"; hash = "sha256-n88XZEaLx10kl7CwkWX+9vPgvAGuwfx2r3yK/Y+VTR4="; };

    # RDNA 1 dGPUs (5700 XT, 5600 XT, 5500 XT)
    "gfx1010" = { name = "gfx101X-dgpu"; hash = "sha256-cCu6pV8+r9F33e7tJsk/kV3SPeQYGIzHnN5twAgZk4w="; };
    "gfx1011" = { name = "gfx101X-dgpu"; hash = "sha256-cCu6pV8+r9F33e7tJsk/kV3SPeQYGIzHnN5twAgZk4w="; };
    "gfx1012" = { name = "gfx101X-dgpu"; hash = "sha256-cCu6pV8+r9F33e7tJsk/kV3SPeQYGIzHnN5twAgZk4w="; };
    "gfx101X-dgpu" = { name = "gfx101X-dgpu"; hash = "sha256-cCu6pV8+r9F33e7tJsk/kV3SPeQYGIzHnN5twAgZk4w="; };

    # RDNA 4
    "gfx1200" = { name = "gfx120X-all"; hash = "sha256-mFsPCCaYYppiv9F1n0h0tYthY+397uFM9SlxnJdh3a8="; };
    "gfx1201" = { name = "gfx120X-all"; hash = "sha256-mFsPCCaYYppiv9F1n0h0tYthY+397uFM9SlxnJdh3a8="; };
    "gfx120X-all" = { name = "gfx120X-all"; hash = "sha256-mFsPCCaYYppiv9F1n0h0tYthY+397uFM9SlxnJdh3a8="; };

    # CDNA / Instinct (MI300, MI350, MI250, MI100) & Next
    "gfx942" = { name = "gfx94X-dcgpu"; hash = "sha256-T5KbrSzt1cwM/j1sXPJBZpVVQPMy9wZUU/uWjSTja6o="; };
    "gfx94X-dcgpu" = { name = "gfx94X-dcgpu"; hash = "sha256-T5KbrSzt1cwM/j1sXPJBZpVVQPMy9wZUU/uWjSTja6o="; };
    "gfx950" = { name = "gfx950-dcgpu"; hash = "sha256-AZkRLia7VrZ2uvJT5NWD0KHKdw29DA7qrmYJR6umE7o="; };
    "gfx950-dcgpu" = { name = "gfx950-dcgpu"; hash = "sha256-AZkRLia7VrZ2uvJT5NWD0KHKdw29DA7qrmYJR6umE7o="; };
    "gfx90a" = { name = "gfx90a"; hash = "sha256-sqvLq1n+IM6YtewXaobMXoKT7KoHwclAIC3mS/5b9M0="; };
    "gfx908" = { name = "gfx908"; hash = "sha256-ehHrYLQtCu06SmUHGR3DErC4uoOthNwZ9z6Ts2C1phI="; };
    "gfx125X-dcgpu" = { name = "gfx125X-dcgpu"; hash = "sha256-O1ugKu5w7+UPDgHpaxAZbpvn8vZURHX268B24k5YRo8="; };

    # Universal
    "multiarch" = { name = "multiarch"; hash = "sha256-qVxy8AUhaPImI2Xf9xwiWTMXIa0KZdp5V9x9lsy3cCE="; };
  };

  targetInfo = tarballTargets.${gfx} or {
    name = gfx;
    hash = "";
  };

  effectiveHash =
    if hash != null then hash
    else if targetInfo.hash != "" then targetInfo.hash
    else throw "pkgs.rocm-therock: No precomputed hash for target '${gfx}'. Please provide an explicit 'hash' argument to rocm-therock.";
in
stdenv.mkDerivation rec {
  pname = "rocm-therock";
  inherit version;

  src = fetchurl {
    url = "https://stable.repo.amd.com/rocm/core/tarball/therock-dist-linux-${targetInfo.name}-${version}.tar.gz";
    hash = effectiveHash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    glibc
    stdenv.cc.cc.lib
    zlib
    numactl
    libdrm
    elfutils
    libtool
  ];

  # Tarball extracts directly into bin/, lib/, include/ rather than a subfolder
  sourceRoot = ".";

  # Do not strip: kernel packs (.kpack), GPU bitcode (.bc), and code objects must remain intact
  dontStrip = true;

  # rocgdb provides wrappers for multiple Python minor versions; these and GPU driver shims are resolved at runtime
  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"
    "libnvidia-ml.so.1"
    "libpython3.10.so.1.0"
    "libpython3.11.so.1.0"
    "libpython3.12.so.1.0"
    "libpython3.13.so.1.0"
    "libpython3.14.so.1.0"
    "libcrypt.so.1"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r * $out/

    # Ensure amdclang/amdclang++/hipcc find glibc headers, CRT objects, and libstdc++ transparently
    local cfg_flags="--gcc-toolchain=${gcc.cc}
-idirafter ${glibc.dev}/include
-B${glibc}/lib
-B${gcc.cc.lib}/lib
-L${glibc}/lib
-L${gcc.cc.lib}/lib
-Wl,-rpath,${glibc}/lib:${gcc.cc.lib}/lib:$out/lib
"

    # Append to rocm.cfg (which clang++.cfg and clang.cfg include via @rocm.cfg)
    if [ -f "$out/lib/llvm/bin/rocm.cfg" ]; then
      printf "\n%s\n" "$cfg_flags" >> "$out/lib/llvm/bin/rocm.cfg"
    fi

    # Also supply standalone configs in bin/ for amdclang/amdclang++
    if [ -d "$out/bin" ]; then
      printf "%s\n" "$cfg_flags" > "$out/bin/amdclang++.cfg"
      printf "%s\n" "$cfg_flags" > "$out/bin/amdclang.cfg"
    fi

    # Wrap hipcc to guarantee ROCM_PATH and HIP_PATH are pre-set
    if [ -f "$out/bin/hipcc" ]; then
      wrapProgram "$out/bin/hipcc" \
        --set-default HIP_PATH "$out" \
        --set-default ROCM_PATH "$out" \
        --prefix PATH : "$out/bin"
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "AMD ROCm ${version} (TheRock) toolchain, libraries, and runtime for ${gfx}";
    homepage = "https://github.com/ROCm/TheRock";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
