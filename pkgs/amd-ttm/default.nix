{ lib, stdenv, python3 }:

stdenv.mkDerivation {
  pname = "amd-ttm";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ python3 ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp amd-ttm.py $out/bin/amd-ttm
    chmod +x $out/bin/amd-ttm
    patchShebangs $out/bin/amd-ttm
  '';

  meta = with lib; {
    description = "Standalone TTM memory inspector for AMD Strix Halo / RDNA 3.5 APUs";
    platforms = platforms.linux;
    mainProgram = "amd-ttm";
  };
}
