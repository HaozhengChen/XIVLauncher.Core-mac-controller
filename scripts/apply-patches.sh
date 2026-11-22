#!/bin/zsh
# Apply the patches in patches/ to the lib/FFXIVQuickLauncher submodule.
# Run after `git submodule update --init`, before building. Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."
SUB=lib/FFXIVQuickLauncher
for p in patches/*.patch; do
  if git -C "$SUB" apply --check "../../$p" 2>/dev/null; then
    git -C "$SUB" apply "../../$p" && echo "applied: $p"
  elif git -C "$SUB" apply --check --reverse "../../$p" 2>/dev/null; then
    echo "already applied: $p"
  else
    echo "cannot apply: $p"; exit 1
  fi
done
