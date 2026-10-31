{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  gcc-unwrapped,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "hrx-loom";
  version = "0.1.0";

  src = fetchurl {
    url = "https://github.com/ROCm/hrx-system/releases/download/v${version}/hrx_loom-${version}-py3-none-manylinux_2_39_x86_64.whl";
    hash = "sha256-TTiXuDzAhXcjWTSHpDcqMdIDlEoWN+XjFDytHQWDuYs=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  buildInputs = [
    gcc-unwrapped.lib
    zlib
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin $out/lib/python3.14/site-packages
    unzip -q $src -d temp-wheel

    # Install binaries and shared libraries
    if [ -d temp-wheel/hrx_loom-${version}.data/scripts ]; then
      for f in temp-wheel/hrx_loom-${version}.data/scripts/*; do
        if [ -f "$f" ]; then
          case "$f" in
            *.so*)
              cp -a "$f" $out/lib/
              ;;
            *)
              cp -a "$f" $out/bin/
              ;;
          esac
        fi
      done
    fi

    # Install python package
    cp -r temp-wheel/loom $out/lib/python3.14/site-packages/
    cp -r temp-wheel/hrx_loom-${version}.dist-info $out/lib/python3.14/site-packages/

    runHook postInstall
  '';

  postFixup = ''
    # Ensure all binaries in $out/bin have $out/lib in their RPATH
    for bin in $out/bin/*; do
      if [ -f "$bin" ] && [ -x "$bin" ]; then
        patchelf --add-rpath "$out/lib" "$bin" 2>/dev/null || true
      fi
    done
  '';

  meta = with lib; {
    description = "ROCm Loom compiler, runtime, and CLI tools for heterogeneous AMD architectures";
    homepage = "https://github.com/ROCm/hrx-system";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "loom-compile";
  };
}
