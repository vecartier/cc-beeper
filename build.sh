#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Claumagotchi..."
swift build -c release 2>&1

BINARY=".build/release/Claumagotchi"
APP_DIR="Claumagotchi.app/Contents/MacOS"

RESOURCES_DIR="Claumagotchi.app/Contents/Resources"

echo "Creating app bundle..."
mkdir -p "$APP_DIR" "$RESOURCES_DIR"
cp "$BINARY" "$APP_DIR/"

# Generate app icon from screenshot if iconutil is available
if [ -f "screenshot.png" ] && command -v iconutil &>/dev/null; then
    ICONSET="/tmp/claumagotchi-iconset.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    sips -z 16 16 screenshot.png --out "$ICONSET/icon_16x16.png" &>/dev/null
    sips -z 32 32 screenshot.png --out "$ICONSET/icon_16x16@2x.png" &>/dev/null
    sips -z 32 32 screenshot.png --out "$ICONSET/icon_32x32.png" &>/dev/null
    sips -z 64 64 screenshot.png --out "$ICONSET/icon_32x32@2x.png" &>/dev/null
    sips -z 128 128 screenshot.png --out "$ICONSET/icon_128x128.png" &>/dev/null
    sips -z 256 256 screenshot.png --out "$ICONSET/icon_128x128@2x.png" &>/dev/null
    sips -z 256 256 screenshot.png --out "$ICONSET/icon_256x256.png" &>/dev/null
    sips -z 512 512 screenshot.png --out "$ICONSET/icon_256x256@2x.png" &>/dev/null
    sips -z 512 512 screenshot.png --out "$ICONSET/icon_512x512.png" &>/dev/null
    sips -z 1024 1024 screenshot.png --out "$ICONSET/icon_512x512@2x.png" &>/dev/null
    iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
    rm -rf "$ICONSET"
fi

cat > Claumagotchi.app/Contents/Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Claumagotchi</string>
    <key>CFBundleIdentifier</key>
    <string>com.claumagotchi.app</string>
    <key>CFBundleName</key>
    <string>Claumagotchi</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Built Claumagotchi.app"
