{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zstd,
  makeBinaryWrapper,
  util-linux,
  libdrm,
  elfutils,
  zlib,
  gcc-unwrapped,
}:

stdenv.mkDerivation rec {
  pname = "xrt-amdxdna";
  version = "2.21.75";

  srcXrt = fetchurl {
    name = "xrt-2.21.75-14.pkg.tar.zst";
    url = "https://geo.mirror.pkgbuild.com/extra/os/x86_64/xrt-1:2.21.75-14-x86_64.pkg.tar.zst";
    hash = "sha256-9jGowffYNufRZF/R5iAlUUqfVFjIiwjy6ww+FwRLzTM=";
  };

  srcPlugin = fetchurl {
    name = "xrt-plugin-amdxdna-2.21.75-2.pkg.tar.zst";
    url = "https://geo.mirror.pkgbuild.com/extra/os/x86_64/xrt-plugin-amdxdna-1:2.21.75-2-x86_64.pkg.tar.zst";
    hash = "sha256-k7HmhMgdckY0X/kw69VsNeW//hiM3K6AZrdnhrPLWy0=";
  };

  srcBoost = fetchurl {
    name = "boost-libs-1.92.0-1.pkg.tar.zst";
    url = "https://geo.mirror.pkgbuild.com/extra/os/x86_64/boost-libs-1.92.0-1-x86_64.pkg.tar.zst";
    hash = "sha256-SxOS5XjkbBsjkQ0cJpVpJ9fphtav1QkL5ZBFr7PAT40=";
  };

  dontUnpack = true;
  autoPatchelfIgnoreMissingDeps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    zstd
    makeBinaryWrapper
  ];

  buildInputs = [
    util-linux.lib
    libdrm
    elfutils
    zlib
    gcc-unwrapped.lib
  ];

  installPhase = ''
        runHook preInstall

        mkdir -p $out
        tar --zstd -C $out -xf ${srcXrt} usr/ --strip-components=1
        tar --zstd -C $out -xf ${srcPlugin} usr/ --strip-components=1
        tar --zstd -C $out -xf ${srcBoost} usr/lib/ --strip-components=1

        # Python auto-init: automatically configure XILINX_XRT when importing in Python
        mkdir -p $out/lib/python3.14/site-packages
        cat << EOF > $out/lib/python3.14/site-packages/xrt_init.py
    import os
    os.environ.setdefault("XILINX_XRT", "$out")
    EOF
        echo "import xrt_init" > $out/lib/python3.14/site-packages/xrt_init.pth

        runHook postInstall
  '';

  postFixup = ''
    for bin in $out/bin/*; do
      if [ -x "$bin" ] && [ ! -L "$bin" ]; then
        wrapProgram "$bin" \
          --set XILINX_XRT "$out" \
          --prefix LD_LIBRARY_PATH : "$out/lib"
      fi
    done
  '';

  meta = with lib; {
    description = "AMD Xilinx Runtime (XRT) and AMDXDNA driver plugin for Ryzen AI NPUs";
    homepage = "https://github.com/amd/xdna-driver";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
