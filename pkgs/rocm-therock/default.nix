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
, targetGfx ? throw "pkgs.rocm-therock: 'targetGfx' must be explicitly specified (e.g. 'gfx1151', 'gfx1100', 'multiarch')."
, hash ? null
}:

let
  # Mapping from targetGfx to upstream TheRock tarball target identifier
  tarballTargets = {
    # AMD APUs (Strix Halo / Strix Point / Kraken Point / Mendocino)
    "gfx1151" = { name = "gfx1151"; hash = "sha256-UN65kwNbwvalq6Xj3o1HbYxRKi7sLL/VqladceC4szc="; };
    "gfx1150" = { name = "gfx1150"; hash = ""; };
    "gfx1152" = { name = "gfx1152"; hash = ""; };
    "gfx1153" = { name = "gfx1153"; hash = ""; };

    # RDNA 3 dGPUs & APUs (7900 XTX, 7800 XT, 7600, 7840U, etc.)
    "gfx1100" = { name = "gfx110X-all"; hash = ""; };
    "gfx1101" = { name = "gfx110X-all"; hash = ""; };
    "gfx1102" = { name = "gfx110X-all"; hash = ""; };
    "gfx1103" = { name = "gfx110X-all"; hash = ""; };
    "gfx110X-all" = { name = "gfx110X-all"; hash = ""; };

    # RDNA 2 dGPUs & APUs (6900 XT, 6800, 6700, 680M, etc.)
    "gfx1030" = { name = "gfx103X-all"; hash = ""; };
    "gfx1031" = { name = "gfx103X-all"; hash = ""; };
    "gfx1032" = { name = "gfx103X-all"; hash = ""; };
    "gfx1035" = { name = "gfx103X-all"; hash = ""; };
    "gfx103X-all" = { name = "gfx103X-all"; hash = ""; };

    # RDNA 4
    "gfx1200" = { name = "gfx120X-all"; hash = ""; };
    "gfx1201" = { name = "gfx120X-all"; hash = ""; };
    "gfx120X-all" = { name = "gfx120X-all"; hash = ""; };

    # CDNA / Instinct (MI300, MI350, MI250, MI100)
    "gfx942" = { name = "gfx94X-dcgpu"; hash = ""; };
    "gfx94X-dcgpu" = { name = "gfx94X-dcgpu"; hash = ""; };
    "gfx950" = { name = "gfx950-dcgpu"; hash = ""; };
    "gfx90a" = { name = "gfx90a"; hash = ""; };
    "gfx908" = { name = "gfx908"; hash = ""; };

    # Universal
    "multiarch" = { name = "multiarch"; hash = ""; };
  };

  targetInfo = tarballTargets.${targetGfx} or {
    name = targetGfx;
    hash = "";
  };

  effectiveHash =
    if hash != null then hash
    else if targetInfo.hash != "" then targetInfo.hash
    else throw "pkgs.rocm-therock: No precomputed hash for target '${targetGfx}'. Please provide an explicit 'hash' argument to rocm-therock.";
in
stdenv.mkDerivation rec {
  pname = "rocm-therock";
  version = "10.1.0";

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
    description = "AMD ROCm 10.1 (TheRock) toolchain, libraries, and runtime for ${targetGfx}";
    homepage = "https://github.com/ROCm/TheRock";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
