#!/bin/zsh
# Builds Pasties.app and installs it to /Applications.
set -e
cd "$(dirname "$0")"

APP=build/Pasties.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "▸ Compiling Swift sources…"
swiftc -O -parse-as-library \
  -target arm64-apple-macosx14.0 \
  -framework Carbon \
  Sources/*.swift \
  -o "$APP/Contents/MacOS/Pasties"

echo "▸ Writing Info.plist…"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Pasties</string>
    <key>CFBundleDisplayName</key><string>Pasties</string>
    <key>CFBundleIdentifier</key><string>com.spiraos.pasties</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>Pasties</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <!-- Menu-bar-only app: no Dock icon, no main window. -->
    <key>LSUIElement</key><true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

echo "▸ Building app icon from Icon.png…"
ICONSET=build/AppIcon.iconset
mkdir -p "$ICONSET"
for pair in 16:16x16 32:16x16@2x 32:32x32 64:32x32@2x 128:128x128 256:128x128@2x 256:256x256 512:256x256@2x 512:512x512 1024:512x512@2x; do
  px="${pair%%:*}"; name="${pair##*:}"
  sips -z "$px" "$px" Icon.png --out "$ICONSET/icon_${name}.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "▸ Code signing (ad-hoc)…"
codesign --force --deep -s - "$APP"

echo "▸ Installing to /Applications…"
rm -rf /Applications/Pasties.app
cp -R "$APP" /Applications/Pasties.app

echo "✓ Done — Pasties.app installed in /Applications"
echo "  Launch it from /Applications (the icon appears in your menu bar)."
