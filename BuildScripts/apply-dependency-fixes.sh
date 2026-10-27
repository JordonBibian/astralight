#!/bin/sh
# Idempotent; never resets a dependency or discards local modifications.
set -eu
cd "$(dirname "$0")/.."
root=$(pwd)
apply_patch() {
  repo=$1
  patch=$2
  if git -C "$repo" apply --reverse --check "$patch" 2>/dev/null; then
    echo "Already applied: $(basename "$patch")"
  elif git -C "$repo" apply --check "$patch"; then
    git -C "$repo" apply "$patch"
    echo "Applied: $(basename "$patch")"
  else
    echo "Dependency differs from the release revision: $repo" >&2
    exit 1
  fi
}
apply_patch moonlight-common/moonlight-common-c "$root/Patches/moonlight-common-initialization.patch"
apply_patch moonlight-common/moonlight-common-c/enet "$root/Patches/enet-enum-flags.patch"
