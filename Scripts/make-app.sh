#!/usr/bin/env bash
# Assembles Tab2PDF.app from the SwiftPM build product, so the result can be
# double clicked instead of launched from a terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${1:-release}"
swift build -c "$CONFIG"

BIN="$(swift build -c "$CONFIG" --show-bin-path)"
APP="$ROOT/build/Tab2PDF.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN/Tab2PDF" "$APP/Contents/MacOS/Tab2PDF"

# SwiftPM keeps package resources in a sibling bundle; copy it next to the binary.
if [ -d "$BIN/Tab2PDF_Tab2PDF.bundle" ]; then
  cp -R "$BIN/Tab2PDF_Tab2PDF.bundle" "$APP/Contents/Resources/"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Tab2PDF</string>
  <key>CFBundleIdentifier</key><string>app.tab2pdf</string>
  <key>CFBundleExecutable</key><string>Tab2PDF</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

echo "built $APP"
