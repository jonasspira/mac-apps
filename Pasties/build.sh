#!/bin/zsh
# Builds SpiraPaste.app and installs it to /Applications.
set -e
cd "$(dirname "$0")"

APP=build/SpiraPaste.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "▸ Compiling Swift sources…"
swiftc -O -parse-as-library \
  -target arm64-apple-macosx14.0 \
  -framework Carbon \
  Sources/*.swift \
  -o "$APP/Contents/MacOS/SpiraPaste"

echo "▸ Writing Info.plist…"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>SpiraPaste</string>
    <key>CFBundleDisplayName</key><string>SpiraPaste</string>
    <key>CFBundleIdentifier</key><string>com.spiraos.spirapaste</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>SpiraPaste</string>
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

echo "▸ Rendering app icon…"
swift scripts/make_icon.swift build/AppIcon.iconset >/dev/null
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

echo "▸ Code signing (ad-hoc)…"
codesign --force --deep -s - "$APP"

echo "▸ Installing to /Applications…"
rm -rf /Applications/SpiraPaste.app
cp -R "$APP" /Applications/SpiraPaste.app

echo "✓ Done — SpiraPaste.app installed in /Applications"
echo "  Launch it from /Applications (the icon appears in your menu bar)."
