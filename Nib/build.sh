#!/bin/zsh
# Builds Nib.app and installs it to /Applications.
set -e
cd "$(dirname "$0")"

APP=build/Nib.app
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "▸ Compiling Swift sources…"
swiftc -O -parse-as-library \
  -target arm64-apple-macosx14.0 \
  Sources/*.swift \
  -o "$APP/Contents/MacOS/Nib"

echo "▸ Writing Info.plist…"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Nib</string>
    <key>CFBundleDisplayName</key><string>Nib</string>
    <key>CFBundleIdentifier</key><string>com.spiraos.nib</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>Nib</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key><string>Markdown Document</string>
            <key>CFBundleTypeRole</key><string>Editor</string>
            <key>LSHandlerRank</key><string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
                <string>public.plain-text</string>
            </array>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string><string>markdown</string><string>mdown</string>
                <string>txt</string><string>text</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "▸ Building app icon from Icon.png (full-bleed)…"
swift scripts/make_icon.swift Icon.png build/AppIcon.iconset >/dev/null
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

echo "▸ Code signing (ad-hoc)…"
codesign --force --deep -s - "$APP"

echo "▸ Installing to /Applications…"
rm -rf /Applications/Nib.app
cp -R "$APP" /Applications/Nib.app

echo "✓ Done — Nib.app installed in /Applications"
