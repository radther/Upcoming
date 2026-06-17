#!/bin/bash
# Bundles the swift build output into a proper macOS .app with Info.plist,
# then ad-hoc codesigns so it can be launched and prompt for Calendar TCC.
set -euo pipefail

ROOT="."
BIN="$ROOT/.build/release/Upcoming"
APP="$ROOT/build/Upcoming.app"

if [[ ! -f "$BIN" ]]; then
  echo "❌ Release binary not found at $BIN"
  echo "   Run: swift build -c release"
  exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/Upcoming"
cp "$ROOT/Sources/Upcoming/Info.plist" "$APP/Contents/Info.plist"

# Minimal PkgInfo for an APPL bundle.
printf 'APPL????' > "$APP/Contents/PkgInfo"

# Set the app icon.
ICON_SRC="$ROOT/Upcoming@1x_Icon.png"
if [[ -f "$ICON_SRC" ]]; then
  mkdir -p "$APP/Contents/Resources/AppIcon.iconset"
  # Generate iconset from the source image at standard sizes.
  sips -z 16 16     "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_16x16.png" > /dev/null
  sips -z 32 32     "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_16x16@2x.png" > /dev/null
  sips -z 32 32     "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_32x32.png" > /dev/null
  sips -z 64 64     "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_32x32@2x.png" > /dev/null
  sips -z 128 128   "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_128x128.png" > /dev/null
  sips -z 256 256   "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_128x128@2x.png" > /dev/null
  sips -z 256 256   "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_256x256.png" > /dev/null
  sips -z 512 512   "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_256x256@2x.png" > /dev/null
  sips -z 512 512   "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_512x512.png" > /dev/null
  sips -z 1024 1024 "$ICON_SRC" --out "$APP/Contents/Resources/AppIcon.iconset/icon_512x512@2x.png" > /dev/null
  iconutil -c icns "$APP/Contents/Resources/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
  rm -rf "$APP/Contents/Resources/AppIcon.iconset"
  echo "✅ Icon set from $ICON_SRC"
else
  echo "⚠️  Icon source not found at $ICON_SRC (skipping icon)"
fi

# Ad-hoc codesign with hardened runtime (needed for EventKit/TCC prompt to work reliably).
codesign --force --deep --sign - \
  --entitlements "$ROOT/Sources/Upcoming/Upcoming.entitlements" \
  --options runtime \
  "$APP"

echo "✅ Built: $APP"
codesign -dv "$APP" 2>&1 | grep -i designat
