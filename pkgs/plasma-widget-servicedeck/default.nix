{ stdenv }:

stdenv.mkDerivation {
  pname = "plasma-widget-servicedeck";
  version = "1.0.0";

  src = ./.;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/org.kde.servicedeck
    cp -r metadata.json contents $out/share/plasma/plasmoids/org.kde.servicedeck/
    runHook postInstall
  '';

  meta.description = "Plasma widget: grouped systemd service control cards (Service Deck)";
}
