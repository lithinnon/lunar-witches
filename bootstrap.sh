#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "==> [bootstrap] Initializing lunar-witches development environment..."

# 1. Wire git hooks
if [ -d .githooks ]; then
  git config core.hooksPath .githooks
  echo "    [ok] Configured git hooks (core.hooksPath = .githooks)"
fi

# 2. Check and mount retrospects worktree
if [ ! -d retrospects ] || [ -z "$(ls -A retrospects 2>/dev/null)" ]; then
  if git show-ref --quiet --verify refs/heads/retrospects; then
    echo "    [..] Mounting retrospects worktree on branch 'retrospects'..."
    git worktree add retrospects retrospects
    echo "    [ok] Mounted retrospects worktree at ./retrospects"
  else
    echo "    [!!] Remote branch 'retrospects' not found locally. Fetching..."
    git fetch origin retrospects:retrospects 2>/dev/null || true
    if git show-ref --quiet --verify refs/heads/retrospects; then
      git worktree add retrospects retrospects
      echo "    [ok] Mounted retrospects worktree at ./retrospects"
    else
      echo "    [--] Branch 'retrospects' not available; skipping worktree mount."
    fi
  fi
else
  echo "    [ok] retrospects worktree already mounted."
fi

# 3. Check spirit-world submodule
if [ -f .gitmodules ] && grep -q "spirit-world" .gitmodules; then
  if [ ! -f spirit-world/default.nix ]; then
    echo "    [..] Attempting to initialize spirit-world private submodule..."
    if git submodule update --init --recursive spirit-world 2>/dev/null; then
      echo "    [ok] Initialized spirit-world submodule."
    else
      echo "    [--] Notice: spirit-world is private (skipped, public fallback active)."
    fi
  else
    echo "    [ok] spirit-world submodule already present."
  fi
fi

# 4. Verify hooks inside spirit-world if present
if [ -d spirit-world/.git ] || [ -f spirit-world/.git ]; then
  if [ -d spirit-world/.githooks ]; then
    git -C spirit-world config core.hooksPath .githooks
    echo "    [ok] Configured spirit-world git hooks."
  fi
fi

echo "==> [bootstrap] Environment successfully bootstrapped."
