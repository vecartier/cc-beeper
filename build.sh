#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Claumagotchi..."
swift build -c release 2>&1

BINARY=".build/release/Claumagotchi"
APP_DIR="Claumagotchi.app/Contents/MacOS"

echo "Creating app bundle..."
mkdir -p "$APP_DIR"
cp "$BINARY" "$APP_DIR/"

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
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Built Claumagotchi.app"
