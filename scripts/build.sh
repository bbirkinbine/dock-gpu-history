#!/bin/bash
# Fast local dev build: compiles with swiftc and wraps in an ad-hoc-signed
# app bundle. For App Store archives, use the Xcode project instead
# (xcodegen generate && open GPUDockHistory.xcodeproj).
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/GPU Dock History.app"
mkdir -p build

swiftc -O Sources/GPUDockHistory/*.swift -o build/gpudockhistory

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

# Dev Info.plist (the Xcode build substitutes variables; here we inline them)
sed -e 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.bbirkinbine.gpu-dock-history.dev/' \
    -e 's/\$(EXECUTABLE_NAME)/gpudockhistory/' \
    Resources/Info.plist > "$APP/Contents/Info.plist"

cp build/gpudockhistory "$APP/Contents/MacOS/"
codesign --force --sign - "$APP"

echo "Built: $APP"
echo "Run:   open \"$APP\""
