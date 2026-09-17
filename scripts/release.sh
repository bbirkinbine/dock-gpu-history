#!/bin/bash
# Cut the distributable build: a release-configured .app, Developer ID signed,
# notarized, stapled, zipped, plus the SHA-256 and cask stanza Homebrew needs.
#
# This is channel 1 + 2 of docs/DISTRIBUTION.md. It needs NO Xcode.app — only
# the Command Line Tools and a Developer ID Application certificate. The Mac
# App Store leg (channel 3) still goes through the Xcode archive; see
# docs/APP_STORE_PUBLISHING.md.
#
# Differences from scripts/build.sh, which is a dev build and not shippable:
#   - real bundle identifier (build.sh appends .dev)
#   - -target arm64-apple-macos13.0, so the binary actually runs on the macOS
#     version Info.plist claims (a bare swiftc build targets the host OS)
#   - hardened runtime + secure timestamp + sandbox entitlement, all three
#     required by notarization
#   - Developer ID signature instead of ad-hoc
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=""
IDENTITY=""
NOTARY_PROFILE="gpu-dock-history-notary"
DO_NOTARIZE=1
ADHOC=0

usage() {
  cat <<EOF
usage: scripts/release.sh [options]

  --version X.Y.Z      override the version (default: MARKETING_VERSION in project.yml)
  --identity NAME      signing identity (default: the sole "Developer ID Application" in the keychain)
  --notary-profile ID  notarytool keychain profile name (default: $NOTARY_PROFILE)
  --skip-notarize      sign and zip, but do not submit to Apple
  --adhoc              ad-hoc sign instead (dry run; the result is NOT distributable)
  -h, --help           this message
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version)        VERSION="${2:?--version needs a value}"; shift 2 ;;
    --identity)       IDENTITY="${2:?--identity needs a value}"; shift 2 ;;
    --notary-profile) NOTARY_PROFILE="${2:?--notary-profile needs a value}"; shift 2 ;;
    --skip-notarize)  DO_NOTARIZE=0; shift ;;
    --adhoc)          ADHOC=1; DO_NOTARIZE=0; shift ;;
    -h|--help)        usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# The toolchain: everything here lives in the Command Line Tools, so a
# not-yet-accepted Xcode license (which gates every xcrun through Xcode.app)
# does not block a release. Fall back rather than fail on it.
if ! swiftc --version >/dev/null 2>&1 && [ -d /Library/Developer/CommandLineTools ]; then
  export DEVELOPER_DIR=/Library/Developer/CommandLineTools
  echo "note: Xcode.app's toolchain is unusable (likely an unaccepted license);"
  echo "      using the Command Line Tools instead. Accept it with:"
  echo "      sudo xcodebuild -license accept"
  swiftc --version >/dev/null 2>&1 || { echo "FAIL: no usable Swift toolchain" >&2; exit 1; }
fi

if [ -z "$VERSION" ]; then
  VERSION=$(sed -n 's/^ *MARKETING_VERSION: *//p' project.yml | head -1 | tr -d '"')
fi
BUILD_NUMBER=$(sed -n 's/^ *CURRENT_PROJECT_VERSION: *//p' project.yml | head -1 | tr -d '"')
: "${VERSION:?could not read MARKETING_VERSION from project.yml}"
: "${BUILD_NUMBER:?could not read CURRENT_PROJECT_VERSION from project.yml}"

BUNDLE_ID="com.bbirkinbine.gpu-dock-history"
OUT="build/release"
APP="$OUT/GPU Dock History.app"
ZIP="$OUT/GPU-Dock-History-$VERSION.zip"
ENTITLEMENTS="Resources/GPUDockHistory.entitlements"
DEPLOY_TARGET="arm64-apple-macos13.0"

# --- preflight ---------------------------------------------------------------
if [ "$ADHOC" -eq 1 ]; then
  IDENTITY="-"
  echo "warning: --adhoc. This exercises the pipeline but produces an artifact"
  echo "         Gatekeeper will reject. Do not publish it."
else
  if [ -z "$IDENTITY" ]; then
    IDENTITY=$(security find-identity -v -p codesigning \
      | sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' | head -1)
  fi
  if [ -z "$IDENTITY" ]; then
    cat >&2 <<EOF
FAIL: no "Developer ID Application" certificate in the keychain.

  Present: $(security find-identity -v -p codesigning | sed -n 's/^ *[0-9]*) [A-F0-9]* //p' | paste -sd'; ' - )

  Create one in Xcode (Settings > Accounts > Manage Certificates > + >
  Developer ID Application) or at developer.apple.com/account/resources/certificates.
  Team G82L6VKCXZ, Account Holder role required.

  To exercise this script without one: scripts/release.sh --adhoc
EOF
    exit 1
  fi
  if [ "$DO_NOTARIZE" -eq 1 ] && \
     ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    cat >&2 <<EOF
FAIL: no notarytool keychain profile named "$NOTARY_PROFILE".

  Store one once (it needs an app-specific password from appleid.apple.com,
  NOT the Apple ID password):

    xcrun notarytool store-credentials "$NOTARY_PROFILE" \\
      --apple-id <your-apple-id-email> \\
      --team-id G82L6VKCXZ \\
      --password <app-specific-password>

  Or re-run with --skip-notarize to stop after signing.
EOF
    exit 1
  fi
fi

echo "==> version $VERSION (build $BUILD_NUMBER), identity: $IDENTITY"

# --- build -------------------------------------------------------------------
rm -rf "$OUT"
mkdir -p "$OUT"

# -target pins the deployment floor. Without it swiftc stamps the host OS into
# LC_BUILD_VERSION and the app refuses to launch on anything older, regardless
# of what LSMinimumSystemVersion says.
swiftc -O -swift-version 5 -target "$DEPLOY_TARGET" \
  Sources/GPUDockHistory/*.swift -o "$OUT/gpudockhistory"

mkdir -p "$APP/Contents/MacOS"
sed -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$BUNDLE_ID/" \
    -e 's/\$(EXECUTABLE_NAME)/gpudockhistory/' \
    -e "s/\$(MARKETING_VERSION)/$VERSION/" \
    -e "s/\$(CURRENT_PROJECT_VERSION)/$BUILD_NUMBER/" \
    Resources/Info.plist > "$APP/Contents/Info.plist"
cp "$OUT/gpudockhistory" "$APP/Contents/MacOS/"

# Icon. actool ships only with Xcode.app, so the asset catalog is compiled here
# the same way scripts/build.sh does it: an .icns from the same PNGs, referenced
# by CFBundleIconFile. The App Store archive uses the catalog proper.
ICONSET_SRC="Resources/Assets.xcassets/AppIcon.appiconset"
if [ ! -d "$ICONSET_SRC" ]; then
  echo "FAIL: $ICONSET_SRC missing; a release build must carry an icon" >&2
  exit 1
fi
ICONSET="$OUT/AppIcon.iconset"
mkdir -p "$ICONSET" "$APP/Contents/Resources"
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
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$APP/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist"

# --- the verify gate, run against the artifact that will actually ship --------
samples=$("$APP/Contents/MacOS/gpudockhistory" --sample 3)
echo "==> sampler: $(echo "$samples" | tr '\n' ' ')"
while read -r v; do
  if [ "$v" = "unavailable" ]; then
    echo "FAIL: release binary reports the GPU statistics key as absent" >&2
    exit 1
  fi
  if ! [[ "$v" =~ ^[0-9]+$ ]] || (( v > 100 )); then
    echo "FAIL: sample '$v' is not an integer in 0-100" >&2
    exit 1
  fi
done <<< "$samples"

# --- sign --------------------------------------------------------------------
# --options runtime (hardened runtime) and --timestamp are both notarization
# requirements; the entitlements keep the sandbox that all three channels share.
SIGN_ARGS=(--force --options runtime --entitlements "$ENTITLEMENTS" --sign "$IDENTITY")
if [ "$ADHOC" -eq 1 ]; then
  SIGN_ARGS+=(--timestamp=none)
else
  SIGN_ARGS+=(--timestamp)
fi
codesign "${SIGN_ARGS[@]}" "$APP"
codesign --verify --strict --verbose=2 "$APP"
echo "==> signed"
codesign --display --verbose=2 "$APP" 2>&1 | sed -n 's/^\(Authority\|TeamIdentifier\|Identifier\)/    &/p'

# --- notarize + staple -------------------------------------------------------
if [ "$DO_NOTARIZE" -eq 1 ]; then
  SUBMIT_ZIP="$OUT/submit.zip"
  ditto -c -k --keepParent "$APP" "$SUBMIT_ZIP"
  echo "==> submitting to Apple (this usually takes a few minutes)"
  xcrun notarytool submit "$SUBMIT_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
  rm -f "$SUBMIT_ZIP"
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
  # The real Gatekeeper question. Only meaningful once stapled.
  spctl --assess --type execute --verbose=2 "$APP"
  echo "==> notarized and stapled"
else
  echo "==> notarization skipped; this .app will be blocked by Gatekeeper"
fi

# --- package -----------------------------------------------------------------
# ditto --keepParent, not `zip`: it preserves the bundle directory and the
# extended attributes the signature covers.
ditto -c -k --keepParent "$APP" "$ZIP"
SHA=$(shasum -a 256 "$ZIP" | cut -d' ' -f1)

# Checksum file for people who download the zip directly. Homebrew does not
# need it (the cask embeds the sha256), but a direct downloader has no other
# way to verify. Written from inside $OUT so it records the bare filename,
# which is what makes `shasum -c` work in the user's Downloads folder.
( cd "$OUT" && shasum -a 256 "$(basename "$ZIP")" > "$(basename "$ZIP").sha256" )

CASK="$OUT/gpu-dock-history.rb"
# "#--" lines are template notes; strip them first so the placeholders they
# mention are never substituted into prose. Then fill in version and sha256.
sed -e '/^[[:space:]]*#--/d' \
    -e "s/@@VERSION@@/$VERSION/" -e "s/@@SHA256@@/$SHA/" \
  packaging/gpu-dock-history.rb.in > "$CASK"

cat <<EOF

================================================================
artifact  $ZIP
checksum  $ZIP.sha256
sha256    $SHA
cask      $CASK  (copy into homebrew-tap/Casks/)

next:
  gh release create v$VERSION "$ZIP" "$ZIP.sha256" \
    --title "GPU Dock History $VERSION" --notes "..."
  then commit the cask to bbirkinbine/homebrew-tap as
    Casks/gpu-dock-history.rb and push. See docs/RELEASING.md.

  note: users need 'brew trust bbirkinbine/tap' or 'brew upgrade' will
        silently skip this cask. See docs/HOMEBREW_DISTRIBUTION.md.
================================================================
EOF
