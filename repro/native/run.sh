#!/bin/sh
# Usage: ./run.sh <path-to-react-native-macos checkout>
set -e
RN="$(cd "$1" && pwd)/packages/react-native"
HERE="$(cd "$(dirname "$0")" && pwd)"
INC="$HERE/build/include/React"; mkdir -p "$INC"
ln -sf "$RN/ReactApple/Libraries/RCTUIKit/RCTPlatformDisplayLink.h" "$INC/"
ln -sf "$RN/Libraries/Image/RCTDisplayWeakRefreshable.h" "$INC/"
xcrun clang++ -fobjc-arc -Wno-everything -I "$HERE/build/include" \
  -x objective-c "$RN/ReactApple/Libraries/RCTUIKit/RCTPlatformDisplayLink.m" \
  -x objective-c++ "$RN/Libraries/Image/RCTDisplayWeakRefreshable.mm" "$HERE/harness.mm" \
  -framework Foundation -framework CoreVideo -framework QuartzCore -framework ApplicationServices \
  -o "$HERE/build/harness"
"$HERE/build/harness"
