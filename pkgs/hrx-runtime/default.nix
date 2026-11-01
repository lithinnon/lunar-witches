{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
  ninja,
  python3,
  pkg-config,
  autoPatchelfHook,
}:

let
  version = "0.1.0";

  # External tar archives required by FetchContent in hrx-system
  libdrmHeadersSrc = fetchurl {
    url = "https://mirrors.edge.kernel.org/gentoo/distfiles/13/libdrm-2.4.134.tar.xz";
    hash = "sha256-rF500VeDDri+5Exqa/OtSXdO8N0qcr2tdKjyAwi1KpU=";
  };

  vulkanHeadersSrc = fetchurl {
    url = "https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/vulkan-sdk-1.4.357.0.tar.gz";
    hash = "sha256-6H3OCBFhUfa2195rb69BSY6H5s+Ej/Fvo71UAhkK1KM=";
  };

  zstdSrc = fetchurl {
    url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz";
    hash = "sha256-6zPlH0mhXgI5UM14Jcp0pKK0Pbg1SCWsJPwbfuCeb6M=";
  };

  # 9 Linux UAPI headers required by libamdf
  linuxConstHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/const.h";
    hash = "sha256-gGyHxE4KGiZ7mWxmnvNvruyU/uRrxFE/DTMtIWlxiFU=";
  };

  linuxIoUringHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/io_uring.h";
    hash = "sha256-hIiyI5iP55ipwcgdE6VQonysHwlr3QFu+eteUa2vRqc=";
  };

  linuxIoUringZcrxHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/io_uring/zcrx.h";
    hash = "sha256-gg2GQhYHQL/1uh2NEtXQRk0OOnZafkVLkB0TS/S5TsA=";
  };

  linuxKfdIoctlHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/kfd_ioctl.h";
    hash = "sha256-20g5gDnBRwLfK1GyRh2A029xYEedRXALfoJgUbHSqZc=";
  };

  linuxKfdSysfsHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/kfd_sysfs.h";
    hash = "sha256-Hybh6kpnm4BgWk2iIbxV6fVw+U+O7MxT+4Jt0Kfe2wA=";
  };

  linuxStatHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/stat.h";
    hash = "sha256-yQCgXgMdmZB021rDVn9lHOLPL5+eCmhoENZFPJ+LlSY=";
  };

  linuxStddefHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/stddef.h";
    hash = "sha256-NwPqNjsPTTt1o6H1m32qoLgfLhjMRZ/t1rHfMx6GYrg=";
  };

  linuxUdmabufHeader = fetchurl {
    url = "https://raw.githubusercontent.com/torvalds/linux/a90ee4305c4a5df72c11b31dacfdc76e00fcf78a/include/uapi/linux/udmabuf.h";
    hash = "sha256-o8hDlHROslSQzTiEv+lefAg3p5s6wxNRZgNkbPBGEvU=";
  };

  linuxXdnaHeader = fetchurl {
    url = "https://raw.githubusercontent.com/amd/xdna-driver/025503bab93a2f347c07a878cf066c05d7662ae0/include/uapi/drm/amdxdna_accel.h";
    hash = "sha256-MLtAh8/AUckXXeE1wW6MOvfYZ+l4m4A3JzafzH7xh2U=";
  };
in
stdenv.mkDerivation {
  pname = "hrx-runtime";
  inherit version;

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = "hrx-system";
    rev = "v${version}";
    hash = "sha256-n0oHtCHMOvoQltPGkTBs2CYXdu/ulp1VF0NT8WUqiBQ=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    python3
    pkg-config
    autoPatchelfHook
  ];

  preConfigure = ''
    mkdir -p external/libdrm external/vulkan external/zstd
    tar -xf ${libdrmHeadersSrc} -C external/libdrm --strip-components=1
    tar -xf ${vulkanHeadersSrc} -C external/vulkan --strip-components=1
    tar -xf ${zstdSrc} -C external/zstd --strip-components=1

    mkdir -p build/_deps/linux_const_header-src/file/linux
    cp ${linuxConstHeader} build/_deps/linux_const_header-src/file/linux/const.h

    mkdir -p build/_deps/linux_io_uring_header-src/file/linux
    cp ${linuxIoUringHeader} build/_deps/linux_io_uring_header-src/file/linux/io_uring.h

    mkdir -p build/_deps/linux_io_uring_zcrx_header-src/file/linux/io_uring
    cp ${linuxIoUringZcrxHeader} build/_deps/linux_io_uring_zcrx_header-src/file/linux/io_uring/zcrx.h

    mkdir -p build/_deps/linux_kfd_ioctl_header-src/file/linux
    cp ${linuxKfdIoctlHeader} build/_deps/linux_kfd_ioctl_header-src/file/linux/kfd_ioctl.h

    mkdir -p build/_deps/linux_kfd_sysfs_header-src/file/linux
    cp ${linuxKfdSysfsHeader} build/_deps/linux_kfd_sysfs_header-src/file/linux/kfd_sysfs.h

    mkdir -p build/_deps/linux_stat_header-src/file/linux
    cp ${linuxStatHeader} build/_deps/linux_stat_header-src/file/linux/stat.h

    mkdir -p build/_deps/linux_stddef_header-src/file/linux
    cp ${linuxStddefHeader} build/_deps/linux_stddef_header-src/file/linux/stddef.h

    mkdir -p build/_deps/linux_udmabuf_header-src/file/linux
    cp ${linuxUdmabufHeader} build/_deps/linux_udmabuf_header-src/file/linux/udmabuf.h

    mkdir -p build/_deps/linux_xdna_header-src/file/drm
    cp ${linuxXdnaHeader} build/_deps/linux_xdna_header-src/file/drm/amdxdna_accel.h
  '';

  cmakeFlags = [
    "-DAMDF_BUILD=ON"
    "-DAMDF_FAMILY_XDNA=ON"
    "-DLIBHRX_BUILD=ON"
    "-DLIBHRX_BUILD_HIP_BINDING=ON"
    "-DLOOM_BUILD=OFF"
    "-DIREE_BUILD_TESTS=OFF"
    "-DIREE_BUILD_BENCHMARKS=OFF"
    "-DIREE_ENABLE_WERROR_FLAG=OFF"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DFETCHCONTENT_SOURCE_DIR_LIBDRM_HEADERS=../external/libdrm"
    "-DFETCHCONTENT_SOURCE_DIR_VULKAN_HEADERS=../external/vulkan"
    "-DFETCHCONTENT_SOURCE_DIR_ZSTD=../external/zstd"
  ];

  postInstall = ''
    if [ -f $out/bin/enumerate ]; then
      ln -sf $out/bin/enumerate $out/bin/amdf-enumerate
    fi

    if [ -d $out/lib ] && [ ! -d $out/lib64 ]; then
      ln -s lib $out/lib64
    elif [ -d $out/lib64 ] && [ ! -d $out/lib ]; then
      ln -s lib64 $out/lib
    fi
  '';

  meta = with lib; {
    description = "ROCm Heterogeneous Runtime eXchange (HRX) and direct DRM driver (libamdf)";
    homepage = "https://github.com/ROCm/hrx-system";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
