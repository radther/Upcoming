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

# Ad-hoc codesign with hardened runtime (needed for EventKit/TCC prompt to work reliably).
codesign --force --deep --sign - \
  --entitlements "$ROOT/Sources/Upcoming/Upcoming.entitlements" \
  --options runtime \
  "$APP"

echo "✅ Built: $APP"
codesign -dv "$APP" 2>&1 | grep -i designat
