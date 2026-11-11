{
  lib,
  stdenv,
  buildNpmPackage,
  autoPatchelfHook,
  nodejs,
  srcOnly,
  python3,
  pkg-config,
  zlib,
  removeReferencesTo,
}:

let
  nodeSources = srcOnly nodejs;
in
buildNpmPackage {
  pname = "pi-extensions";
  version = "1.0.0";
  src = ./.;

  npmDepsHash = "sha256-BVfrUWhGnSLWdlIo/Fn/vp7rDQ8WbKtwaGnkphFQ5F0=";
  npmFlags = [ "--legacy-peer-deps" ];

  nativeBuildInputs = [
    autoPatchelfHook
    python3
    pkg-config
  ];

  buildInputs = [
    zlib
    stdenv.cc.cc.lib
  ];

  buildPhase = ''
    runHook preBuild

    pushd node_modules/better-sqlite3
    npm run build-release --offline --nodedir="${nodeSources}"
    rm -rf build/Release/{.deps,obj,obj.target,test_extension.node}
    find build -type f -exec ${lib.getExe removeReferencesTo} -t "${nodeSources}" {} +
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    local outPkg="$out/lib/node_modules/pi-extensions"
    mkdir -p "$outPkg"
    cp package.json "$outPkg/"
    # Drop musl optional native prebuild so autoPatchelfHook targets glibc only.
    rm -rf node_modules/@napi-rs/keyring-linux-x64-musl
    cp -r node_modules "$outPkg/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Declarative npm extension bundle for Pi Coding Agent";
    platforms = [ "x86_64-linux" ];
  };
}
