{
  lib,
  stdenv,
  makeWrapper,
  bash,
  coreutils,
  gnugrep,
}:

stdenv.mkDerivation {
  pname = "asus-power-sync";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp asus-power-sync.sh $out/bin/asus-power-sync
    chmod +x $out/bin/asus-power-sync
    wrapProgram $out/bin/asus-power-sync \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          coreutils
          gnugrep
        ]
      }
  '';

  meta = with lib; {
    description = "Unified ASUS laptop hardware power state coordinator (Panel Overdrive & SD Card PCIe PM)";
    platforms = platforms.linux;
    mainProgram = "asus-power-sync";
  };
}
