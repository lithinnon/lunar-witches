{
  lib,
  stdenv,
  python3,
}:

stdenv.mkDerivation {
  pname = "mem-ttm";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ python3 ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp mem-ttm.py $out/bin/mem-ttm
    chmod +x $out/bin/mem-ttm
    patchShebangs $out/bin/mem-ttm
  '';

  meta = with lib; {
    description = "Standalone Linux DRM Translation Table Manager (TTM) memory inspector";
    platforms = platforms.linux;
    mainProgram = "mem-ttm";
  };
}
