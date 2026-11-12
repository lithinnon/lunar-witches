{
  symlinkJoin,
  makeWrapper,
  equibop,
}:

# Equibop bundles arRPC (arrpc-bun) for process-based Rich Presence game detection.
# arRPC natively supports loading custom fixes from $ARRPC_DATA_DIR/detectable_fixes.json,
# but Equibop does not pass ARRPC_DATA_DIR by default.
# This wrapper sets ARRPC_DATA_DIR defaulting to ${XDG_CONFIG_HOME:-$HOME/.config}/equibop.
symlinkJoin {
  name = "equibop-${equibop.version}";
  paths = [ equibop ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    rm $out/bin/equibop
    makeWrapper ${equibop}/bin/equibop $out/bin/equibop \
      --run 'export ARRPC_DATA_DIR="''${ARRPC_DATA_DIR:-''${XDG_CONFIG_HOME:-$HOME/.config}/equibop}"'
  '';
  meta = equibop.meta or { };
  passthru = (equibop.passthru or { }) // {
    unwrapped = equibop;
  };
}
