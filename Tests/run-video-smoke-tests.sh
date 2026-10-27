#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d "${TMPDIR:-/tmp}/astralight-video-tests.XXXXXX")
trap 'rm -rf "$build_dir"' EXIT
xcrun --sdk macosx clang -fobjc-arc -fmodules -mmacosx-version-min=14.0 \
  -I "$repo_dir/Limelight/Stream" \
  "$repo_dir/Tests/VideoPipelineSmokeTests.m" \
  "$repo_dir/Limelight/Stream/SpatialVideoDecoder.m" \
  -framework Foundation -framework CoreMedia -framework CoreVideo \
  -framework VideoToolbox -framework Metal -framework MetalFX \
  -o "$build_dir/video-tests"
MTL_DEBUG_LAYER=1 "$build_dir/video-tests"
