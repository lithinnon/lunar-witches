{ stdenv }:

stdenv.mkDerivation {
  pname = "plasma-widget-amdgpuboost";
  version = "1.0.0";

  src = ./.;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/org.kde.amdgpuboost
    cp -r metadata.json contents $out/share/plasma/plasmoids/org.kde.amdgpuboost/
    runHook postInstall
  '';

  meta.description = "Plasma widget: AMDGPU boost mode & clock controller (amdgpu-boost)";
}
