{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  zlib,
  zstd,
  brotli,
  libpng,
  freetype,
  fontconfig,
  libGL,
  libdrm,
  wayland,
  libxkbcommon,
  dbus,
  libx11,
  libxau,
  libxdmcp,
  libsm,
  libice,
  libxcb,
  libxcb-util,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
  libxcb-cursor,
  libtraceevent,
  libtracefs,
  libxml2_13,
  version ? "2026-10-02-1872",
  hash ? "sha256-FJZH18yvBPYzBlYIlp9MRCUOFeXth0RZeax4zsP58C0=",
}:

let
  runtimeLibs = [
    stdenv.cc.cc.lib
    zlib
    zstd
    brotli
    libpng
    freetype
    fontconfig
    libGL
    libdrm
    wayland
    libxkbcommon
    dbus
    libx11
    libxau
    libxdmcp
    libsm
    libice
    libxcb
    libxcb-util
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-wm
    libxcb-cursor
    libtraceevent
    libtracefs
    libxml2_13
  ];
in
stdenv.mkDerivation rec {
  pname = "radeon-developer-tool-suite";
  inherit version;

  src = fetchurl {
    url = "https://gpuopen.com/download/RadeonDeveloperToolSuite-${version}.tgz";
    inherit hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = runtimeLibs;

  # Do not strip binaries as internal symbol and debug structures should remain intact
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    local targetDir="$out/libexec/radeon-developer-tool-suite"
    mkdir -p "$targetDir" "$out/bin"

    cp -r * "$targetDir/"

    # Wrap main executables
    for bin in \
      RadeonGPUProfiler \
      RadeonDeveloperPanel \
      RadeonDeveloperPanelCLI \
      RadeonDeveloperService \
      RadeonDeveloperServiceCLI \
      RadeonMemoryVisualizer \
      RadeonRaytracingAnalyzer \
      RadeonGPUAnalyzer-bin \
      rgd \
      rtda
    do
      if [ -e "$targetDir/$bin" ]; then
        makeWrapper "$targetDir/$bin" "$out/bin/$bin" \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}:$targetDir/lib" \
          --set-default QT_PLUGIN_PATH "$targetDir/plugins" \
          --set-default QT_QPA_PLATFORM_PLUGIN_PATH "$targetDir/plugins/platforms"
      fi
    done

    # User-friendly lowercase symlinks
    ln -s "$out/bin/RadeonGPUProfiler" "$out/bin/rgp"
    ln -s "$out/bin/RadeonDeveloperPanel" "$out/bin/rdp"
    ln -s "$out/bin/RadeonMemoryVisualizer" "$out/bin/rmv"
    ln -s "$out/bin/RadeonRaytracingAnalyzer" "$out/bin/rra"
    ln -s "$out/bin/RadeonDeveloperService" "$out/bin/rds"
    ln -s "$out/bin/RadeonDeveloperServiceCLI" "$out/bin/rds-cli"
    ln -s "$out/bin/RadeonGPUAnalyzer-bin" "$out/bin/rga"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "radeon-gpu-profiler";
      desktopName = "Radeon GPU Profiler";
      genericName = "GPU Profiler";
      exec = "RadeonGPUProfiler %F";
      comment = "Profile and inspect GPU workloads on AMD Radeon hardware";
      categories = [
        "Development"
        "Profiling"
      ];
      mimeTypes = [ "application/x-rgp" ];
      terminal = false;
    })
    (makeDesktopItem {
      name = "radeon-developer-panel";
      desktopName = "Radeon Developer Panel";
      genericName = "Developer Panel";
      exec = "RadeonDeveloperPanel";
      comment = "Target connection and frame capture manager for AMD Radeon tools";
      categories = [ "Development" ];
      terminal = false;
    })
    (makeDesktopItem {
      name = "radeon-memory-visualizer";
      desktopName = "Radeon Memory Visualizer";
      genericName = "GPU Memory Visualizer";
      exec = "RadeonMemoryVisualizer %F";
      comment = "Inspect GPU memory allocations on AMD Radeon hardware";
      categories = [
        "Development"
        "Profiling"
      ];
      mimeTypes = [ "application/x-rmv" ];
      terminal = false;
    })
    (makeDesktopItem {
      name = "radeon-raytracing-analyzer";
      desktopName = "Radeon Raytracing Analyzer";
      genericName = "Raytracing Analyzer";
      exec = "RadeonRaytracingAnalyzer %F";
      comment = "Inspect raytracing acceleration structures and ray pipelines";
      categories = [
        "Development"
        "Profiling"
      ];
      mimeTypes = [ "application/x-rra" ];
      terminal = false;
    })
  ];

  meta = with lib; {
    description = "AMD Radeon Developer Tool Suite (RGP, RMV, RRA, RDP, RGA)";
    homepage = "https://gpuopen.com/rgp/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "RadeonGPUProfiler";
  };
}
