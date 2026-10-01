{
  lib,
  stdenv,
  makeWrapper,
  bash,
  coreutils,
  gawk,
  gnused,
  gnugrep,
  systemd,
  dbus,
  libnotify,
  asusctl,
  kdePackages,
}:

stdenv.mkDerivation {
  pname = "amdgpu-boost";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp amdgpu-boost.sh $out/bin/amdgpu-boost
    chmod +x $out/bin/amdgpu-boost
    wrapProgram $out/bin/amdgpu-boost \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          coreutils
          gawk
          gnused
          gnugrep
          systemd
          dbus
          libnotify
          asusctl
          kdePackages.libkscreen
        ]
      }
  '';

  meta = with lib; {
    description = "Dynamic AMD GPU Performance Boost, DPM Governor & Auto-Display Daemon";
    platforms = platforms.linux;
    mainProgram = "amdgpu-boost";
  };
}
