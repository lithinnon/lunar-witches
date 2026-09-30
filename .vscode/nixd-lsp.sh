#!/bin/sh
#
# Why this wrapper exists:
# 1. Self-contained workspace: nixd is defined inside this repository's flake.nix
#    and is not installed globally on the host system.
# 2. Startup race condition: VS Code extensions activate in parallel. Extension
#    `jnoortheen.nix-ide` synchronously checks `$PATH` for the LSP binary before
#    environment loaders (e.g. nix-env-selector) can finish exporting the devShell.
#    Pointing `nix.serverPath` directly to this script guarantees that nixd always
#    launches on demand inside the flake's devShell without relying on direnv or
#    starting VS Code via `nix develop --command code .`.
# 3. Environment isolation: nixd and its children (such as nixfmt) run directly
#    within the pinned flake environment.
#

exec nix develop "${0%/*}/.." --command nixd "$@" 2>/dev/null
