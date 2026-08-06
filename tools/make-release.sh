#!/bin/bash
# Packages Cue Booth for a GitHub release.
#
#   tools/make-release.sh 1.2.0            # build dist/CueBooth-1.2.0.zip
#   tools/make-release.sh 1.2.0 --publish  # also create the GitHub release
#
# The zip is what people download, so the site can link
# .../releases/latest/download/CueBooth.zip and never need updating. That URL
# only resolves if the asset name stays constant, hence the unversioned copy.
#
# Builds are ad-hoc signed, not notarised: that needs a Developer ID from the
# paid Apple Developer Program. Gatekeeper therefore blocks the download until
# the user clears the quarantine flag, which the release notes explain. Two
# consequences worth remembering before changing any of this:
#
#   - the warning is expected, not a packaging mistake
#   - ad-hoc signatures change with the contents, so macOS treats each release
#     as a different app and Accessibility permission has to be granted again
#
# Switching to Developer ID later means changing the identity in make-app.sh
# and adding a notarytool submit/staple step here.

set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "usage: tools/make-release.sh <version> [--publish]" >&2
  exit 1
fi
TAG="v$VERSION"
APP="dist/Cue Booth.app"
ZIP="dist/CueBooth.zip"
VERSIONED="dist/CueBooth-$VERSION.zip"

echo "==> Building $TAG"
CUE_VERSION="$VERSION" tools/make-app.sh

if [ ! -f "$APP/Contents/Resources/media-control/LICENSE.txt" ]; then
  echo "!! media-control licence missing from the bundle — BSD-3 requires it" >&2
  exit 1
fi

echo "==> Packaging"
rm -f "$ZIP" "$VERSIONED"
# ditto keeps the bundle's symlinks and signature intact; zip -r does not.
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
cp "$ZIP" "$VERSIONED"

echo "==> Verifying the packaged copy still validates"
rm -rf dist/verify && mkdir -p dist/verify
ditto -x -k "$ZIP" dist/verify
codesign --verify --deep --strict "dist/verify/Cue Booth.app"
echo "    signature survives the round trip"
rm -rf dist/verify

SHA="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
SIZE="$(du -h "$ZIP" | awk '{print $1}')"
echo "==> $ZIP ($SIZE)"
echo "    sha256 $SHA"

if [ "${2:-}" != "--publish" ]; then
  echo "==> Not publishing (pass --publish to create the GitHub release)"
  exit 0
fi

NOTES="$(cat <<EOF
Cue Booth $VERSION — the macOS half of Cue. Self-contained: the MediaRemote
adapter is bundled, so Homebrew is not required.

**Install**

1. Download \`CueBooth.zip\` below and unzip it
2. Move **Cue Booth.app** to \`/Applications\`
3. Clear the download quarantine, then open it:

\`\`\`bash
xattr -dr com.apple.quarantine "/Applications/Cue Booth.app"
open "/Applications/Cue Booth.app"
\`\`\`

That step is needed because this build is signed but **not notarised** —
notarisation requires a paid Apple Developer account. Without clearing the
flag macOS reports that the developer cannot be verified. You can also
right-click the app and choose **Open** instead of using the command.

**The iPhone app is not included.** It has to be built and sideloaded with
Xcode — see the [getting started guide](https://github.com/nikets40/cue#3-build-and-install-the-iphone-app).

\`sha256  $SHA\`

Bundled \`media-control\` is BSD-3-Clause, © 2025 Jonas van den Berg.
EOF
)"

echo "==> Publishing $TAG"
if gh release view "$TAG" >/dev/null 2>&1; then
  gh release upload "$TAG" "$ZIP" "$VERSIONED" --clobber
  echo "    updated existing release $TAG"
else
  gh release create "$TAG" "$ZIP" "$VERSIONED" \
    --title "Cue Booth $VERSION" --notes "$NOTES"
  echo "    created release $TAG"
fi
