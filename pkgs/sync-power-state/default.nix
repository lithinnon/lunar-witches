{ lib
, stdenv
, makeWrapper
, bash
, coreutils
, gnugrep
, kdePackages
}:

stdenv.mkDerivation {
  pname = "sync-power-state";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp sync-power-state.sh $out/bin/sync-power-state
    chmod +x $out/bin/sync-power-state
    wrapProgram $out/bin/sync-power-state \
      --prefix PATH : ${lib.makeBinPath [
        bash
        coreutils
        gnugrep
        kdePackages.libkscreen
      ]}
  '';

  meta = with lib; {
    description = "Seamless AC vs Battery display and platform state switcher";
    platforms = platforms.linux;
    mainProgram = "sync-power-state";
  };
}
