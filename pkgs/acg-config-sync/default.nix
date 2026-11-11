{
  lib,
  stdenv,
  python3,
  git,
  makeWrapper,
}:

stdenv.mkDerivation {
  pname = "acg-config-sync";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ python3 ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    siteDir="$out/${python3.sitePackages}"
    install -Dm644 acg_config_sync.py "$siteDir/acg_config_sync.py"
    install -Dm755 nte-config-sync "$out/bin/nte-config-sync"
    install -Dm755 wuwa-config-sync "$out/bin/wuwa-config-sync"

    patchShebangs "$out/bin"

    for bin in "$out/bin/nte-config-sync" "$out/bin/wuwa-config-sync"; do
      wrapProgram "$bin" \
        --prefix PYTHONPATH : "$siteDir" \
        --prefix PATH : ${lib.makeBinPath [ git ]}
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Sync, merge, and wrap Unreal Engine configs for ACG titles";
    platforms = platforms.linux;
  };
}
