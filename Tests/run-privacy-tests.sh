#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d /private/tmp/astralight-privacy-test.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT
sdk=$(xcrun --sdk macosx --show-sdk-path)
xcrun --sdk macosx clang -fobjc-arc -framework Foundation -lxml2 \
  -I "$sdk/usr/include/libxml2" -I Limelight/Network -I Limelight/Utility \
  -include Foundation/Foundation.h -include Limelight/Utility/Logger.h \
  Tests/HTTPResponsePrivacyTests.m Limelight/Network/HttpResponse.m -o "$test_dir/privacy-test"
"$test_dir/privacy-test" > "$test_dir/output" 2> "$test_dir/errors"
if rg -q 'ASTRALIGHT_TEST_SECRET' "$test_dir/output" "$test_dir/errors"; then
  echo 'FAIL: sensitive response text reached stdout/stderr' >&2
  exit 1
fi
cat "$test_dir/output"
