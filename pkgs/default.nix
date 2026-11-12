{ self, ... }:

let
  inTreePackages = {
    acg-config-sync = ./acg-config-sync;
    mem-ttm = ./mem-ttm;
    asus-power-sync = ./asus-power-sync;
    service-deck-helper = ./service-deck-helper;
    plasma-widget-servicedeck = ./plasma-widget-servicedeck;
    xrt-amdxdna = ./xrt-amdxdna;
    triellama = ./triellama;
    radeon-developer-tool-suite = ./radeon-developer-tool-suite;
    hrx-loom = ./hrx-loom;
    hrx-runtime = ./hrx-runtime;
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages = (builtins.mapAttrs (_name: path: pkgs.callPackage path { }) inTreePackages) // {
        rocm-therock-gfx1151 = pkgs.callPackage ./rocm-therock { gfx = "gfx1151"; };
      };
    };

  flake.overlays.default =
    final: prev:
    (builtins.mapAttrs (_name: path: final.callPackage path { }) inTreePackages)
    // {
      rocm-therock = final.callPackage ./rocm-therock;
      rocm-therock-gfx1151 = final.callPackage ./rocm-therock { gfx = "gfx1151"; };

      # codex vendored crates require system libraries under nixpkgs cargo-setup-hook defaults:
      # aws-lc (AWS_LC_SYS_USE_SYSTEM=1), zstd (ZSTD_SYS_USE_PKG_CONFIG=1), sqlite (LIBSQLITE3_SYS_USE_PKG_CONFIG=1),
      # rust-jemalloc-sys (JEMALLOC_OVERRIDE), oniguruma (RUSTONIG_SYSTEM_LIBONIG=1).
      codex = prev.codex.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [
          final.aws-lc
          final.zstd
          final.sqlite
          final.rust-jemalloc-sys
          final.oniguruma
        ];
      });

      # Upstream nixpkgs unstable bumped mcp to 2.x where fastmcp-slim is marked broken.
      # Override fastmcp-slim with nixpkgs's backwards-compatible mcp_1 (1.29.0).
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyFinal: pyPrev: {
          fastmcp-slim = pyPrev.fastmcp-slim.override {
            mcp = pyFinal.mcp_1;
          };

          # primp vendored zstd-sys and aws-lc-sys require pkg-config, zstd, and aws-lc
          # under nixpkgs cargo-setup-hook defaults (ZSTD_SYS_USE_PKG_CONFIG=1, AWS_LC_SYS_USE_SYSTEM=1).
          primp = pyPrev.primp.overridePythonAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              final.pkg-config
            ];
            buildInputs = (old.buildInputs or [ ]) ++ [
              final.zstd
              final.aws-lc
            ];
          });

          # chromadb rust bindings (sqlx-macros and tikv-jemalloc-sys) require sqlite and rust-jemalloc-sys
          # under nixpkgs cargo-setup-hook defaults (LIBSQLITE3_SYS_USE_PKG_CONFIG=1, JEMALLOC_OVERRIDE).
          chromadb = pyPrev.chromadb.overridePythonAttrs (old: {
            buildInputs = (old.buildInputs or [ ]) ++ [
              final.sqlite
              final.rust-jemalloc-sys
            ];
          });
        })
      ];
    };
}
