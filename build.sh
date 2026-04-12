#!/bin/bash
set -e

# Code signing identity.
# Default is ad-hoc (-) for local development.
# Set SIGNING_IDENTITY='Developer ID Application: Name (TEAMID)' for distribution builds.
# Example: SIGNING_IDENTITY='Developer ID Application: Jane Smith (ABCDE12345)' make dmg
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"

cd "$(dirname "$0")"

echo "Building CC-Beeper..."
swift build -c release 2>&1

BINARY=".build/release/CC-Beeper"
APP_DIR="CC-Beeper.app/Contents/MacOS"

RESOURCES_DIR="CC-Beeper.app/Contents/Resources"

echo "Creating app bundle..."
mkdir -p "$APP_DIR" "$RESOURCES_DIR"
cp "$BINARY" "$APP_DIR/"

# Copy shell image assets
cp Sources/shells/beeper-*.png "$RESOURCES_DIR/" 2>/dev/null

# Copy button image assets
cp Sources/buttons/*.png "$RESOURCES_DIR/" 2>/dev/null

# Copy font assets
cp Sources/fonts/*.ttf "$RESOURCES_DIR/" 2>/dev/null

# Copy cover image for onboarding
cp docs/cover.png "$RESOURCES_DIR/cover.png" 2>/dev/null

# Generate app icon from icon.png (transparent, no background)
if [ -f "icon.png" ] && command -v iconutil &>/dev/null; then
    ICONSET="/tmp/cc-beeper-iconset.iconset"
    rm -rf "$ICONSET"
    mkdir -p "$ICONSET"
    for s in 16 32 64 128 256 512 1024; do
        sips -z $s $s icon.png --out "$ICONSET/tmp_${s}.png" &>/dev/null
    done
    cp "$ICONSET/tmp_16.png"   "$ICONSET/icon_16x16.png"
    cp "$ICONSET/tmp_32.png"   "$ICONSET/icon_16x16@2x.png"
    cp "$ICONSET/tmp_32.png"   "$ICONSET/icon_32x32.png"
    cp "$ICONSET/tmp_64.png"   "$ICONSET/icon_32x32@2x.png"
    cp "$ICONSET/tmp_128.png"  "$ICONSET/icon_128x128.png"
    cp "$ICONSET/tmp_256.png"  "$ICONSET/icon_128x128@2x.png"
    cp "$ICONSET/tmp_256.png"  "$ICONSET/icon_256x256.png"
    cp "$ICONSET/tmp_512.png"  "$ICONSET/icon_256x256@2x.png"
    cp "$ICONSET/tmp_512.png"  "$ICONSET/icon_512x512.png"
    cp "$ICONSET/tmp_1024.png" "$ICONSET/icon_512x512@2x.png"
    rm -f "$ICONSET"/tmp_*.png
    iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns"
    rm -rf "$ICONSET"
fi

cat > CC-Beeper.app/Contents/Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CC-Beeper</string>
    <key>CFBundleIdentifier</key>
    <string>com.vecartier.cc-beeper</string>
    <key>CFBundleName</key>
    <string>CC-Beeper</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>ATSApplicationFontsPath</key>
    <string>.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>CC-Beeper needs microphone access to record your voice for transcription.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>CC-Beeper uses on-device speech recognition to transcribe your voice.</string>
</dict>
</plist>
PLIST

echo "Built CC-Beeper.app"

# Strip extended attributes (quarantine, etc.) from the bundle.
# Apple's notary service silently hangs on bundles containing com.apple.quarantine xattrs.
xattr -cr CC-Beeper.app

# Hardened runtime + secure timestamp are required for notarization.
# Enable them only for Developer ID signing (not for ad-hoc "-" local builds).
if [ "$SIGNING_IDENTITY" = "-" ]; then
    codesign --force --deep --sign "$SIGNING_IDENTITY" --entitlements CC-Beeper.entitlements CC-Beeper.app
else
    codesign --force --deep --sign "$SIGNING_IDENTITY" \
        --entitlements CC-Beeper.entitlements \
        --options runtime \
        --timestamp \
        CC-Beeper.app
fi
echo "Signed CC-Beeper.app (identity: $SIGNING_IDENTITY)"

# Install the fresh build into /Applications so the running copy never drifts
# from the source tree. Skip with SKIP_INSTALL=1 for CI / DMG builds.
if [ "${SKIP_INSTALL:-0}" != "1" ]; then
    echo "Installing to /Applications..."
    osascript -e 'tell application "CC-Beeper" to quit' >/dev/null 2>&1 || true
    pkill -f "/Applications/CC-Beeper.app/Contents/MacOS/CC-Beeper" >/dev/null 2>&1 || true
    rm -rf /Applications/CC-Beeper.app
    cp -R CC-Beeper.app /Applications/
    echo "Installed /Applications/CC-Beeper.app"
fi
