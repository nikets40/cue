#!/bin/bash
# Assembles dist/Cue Booth.app — a self-contained menu bar app with the
# MediaRemote adapter vendored inside, so it no longer depends on the
# Homebrew media-control install.
#
#   tools/make-app.sh [--install]
#
# --install also copies the result to /Applications.

set -euo pipefail
cd "$(dirname "$0")/.."

APP="dist/Cue Booth.app"
CONTENTS="$APP/Contents"
# Overridable so make-release.sh can stamp the tag it's publishing.
VERSION="${CUE_VERSION:-1.0.0}"

echo "==> Building release binary"
(cd booth && swift build -c release)

echo "==> Laying out bundle"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp booth/.build/release/CueBooth "$CONTENTS/MacOS/CueBooth"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Cue Booth</string>
  <key>CFBundleDisplayName</key><string>Cue Booth</string>
  <key>CFBundleIdentifier</key><string>com.niket.cuebooth</string>
  <key>CFBundleExecutable</key><string>CueBooth</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <!-- Menu bar app: no Dock icon, no app switcher entry. -->
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>Cue Booth controls QuickTime Player playback from your phone, and asks Chrome which site is playing so the right artwork is shown.</string>
</dict>
</plist>
PLIST

echo "==> Generating icon"
TMP_ICON="$(mktemp -d)"
swift tools/make-macos-icon.swift "$TMP_ICON/master.png" >/dev/null
mkdir -p "$TMP_ICON/AppIcon.iconset"
for size in 16 32 64 128 256 512; do
  sips -z $size $size "$TMP_ICON/master.png" --out "$TMP_ICON/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null 2>&1
  double=$((size * 2))
  sips -z $double $double "$TMP_ICON/master.png" --out "$TMP_ICON/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null 2>&1
done
iconutil -c icns "$TMP_ICON/AppIcon.iconset" -o "$CONTENTS/Resources/AppIcon.icns"
rm -rf "$TMP_ICON"

echo "==> Vendoring mediaremote-adapter"
# The media-control wrapper resolves ../lib and ../Frameworks relative to its
# own directory, so the brew layout is copied wholesale and keeps working.
BREW_PREFIX="$(brew --prefix media-control 2>/dev/null || true)"
if [ -z "$BREW_PREFIX" ] || [ ! -d "$BREW_PREFIX" ]; then
  echo "!! media-control not installed via brew — run: brew install media-control" >&2
  exit 1
fi
mkdir -p "$CONTENTS/Resources/media-control"
ditto "$BREW_PREFIX/bin" "$CONTENTS/Resources/media-control/bin"
ditto "$BREW_PREFIX/lib" "$CONTENTS/Resources/media-control/lib"
ditto "$BREW_PREFIX/Frameworks" "$CONTENTS/Resources/media-control/Frameworks"
# BSD-3 requires the notice to travel with any redistributed binary, and the
# release ships this bundle wholesale. Homebrew doesn't install a copy, so the
# repo carries one — see third_party/README.md.
cp third_party/media-control-LICENSE.txt "$CONTENTS/Resources/media-control/LICENSE.txt"

echo "==> Signing"
# Ad-hoc is enough for a locally built personal app; a real identity is used
# when one is available so TCC grants stick across rebuilds.
IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk '/Apple Development/ {print $2; exit}')"
if [ -n "$IDENTITY" ]; then
  codesign --force --deep --sign "$IDENTITY" "$APP" 2>/dev/null \
    || codesign --force --deep --sign - "$APP"
else
  codesign --force --deep --sign - "$APP"
fi
codesign --verify --deep "$APP" && echo "    signature verifies"

if [ "${1:-}" = "--install" ]; then
  echo "==> Installing to /Applications"
  rm -rf "/Applications/Cue Booth.app"
  ditto "$APP" "/Applications/Cue Booth.app"
  echo "    /Applications/Cue Booth.app"
fi

echo "==> Done: $APP"
du -sh "$APP" | sed 's/^/    /'
