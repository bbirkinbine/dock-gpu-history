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

# Embed the app icon. The Xcode build compiles Resources/Assets.xcassets via
# actool; this bare swiftc build can't (actool needs full Xcode), so build an
# AppIcon.icns from the same PNGs with iconutil (Command Line Tools) and drop it
# in. Best-effort: skipped if iconutil or the appiconset is missing.
ICONSET_SRC="Resources/Assets.xcassets/AppIcon.appiconset"
if command -v iconutil >/dev/null 2>&1 && [ -d "$ICONSET_SRC" ]; then
  ICONSET="build/AppIcon.iconset"
  rm -rf "$ICONSET"; mkdir -p "$ICONSET"
  cp "$ICONSET_SRC/icon_16.png"   "$ICONSET/icon_16x16.png"
  cp "$ICONSET_SRC/icon_32.png"   "$ICONSET/icon_16x16@2x.png"
  cp "$ICONSET_SRC/icon_32.png"   "$ICONSET/icon_32x32.png"
  cp "$ICONSET_SRC/icon_64.png"   "$ICONSET/icon_32x32@2x.png"
  cp "$ICONSET_SRC/icon_128.png"  "$ICONSET/icon_128x128.png"
  cp "$ICONSET_SRC/icon_256.png"  "$ICONSET/icon_128x128@2x.png"
  cp "$ICONSET_SRC/icon_256.png"  "$ICONSET/icon_256x256.png"
  cp "$ICONSET_SRC/icon_512.png"  "$ICONSET/icon_256x256@2x.png"
  cp "$ICONSET_SRC/icon_512.png"  "$ICONSET/icon_512x512.png"
  cp "$ICONSET_SRC/icon_1024.png" "$ICONSET/icon_512x512@2x.png"
  mkdir -p "$APP/Contents/Resources"
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
  # Dev bundle references the icns via CFBundleIconFile (the Xcode build uses
  # the asset-catalog CFBundleIconName instead).
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" \
    "$APP/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" \
       "$APP/Contents/Info.plist"
fi

codesign --force --sign - "$APP"

echo "Built: $APP"
echo "Run:   open \"$APP\""
