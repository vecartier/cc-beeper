#!/bin/bash
set -e

cd "$(dirname "$0")"

# Build the app first
./build.sh

echo "Creating branded DMG..."

VOLUME_NAME="CC-Beeper"
DMG_FINAL="CC-Beeper.dmg"
DMG_TEMP="/tmp/cc-beeper-dmg-rw.dmg"
STAGING="/tmp/cc-beeper-dmg"

# Clean up any previous staging
rm -rf "$STAGING" "$DMG_FINAL" "$DMG_TEMP"

# Stage the DMG contents
mkdir -p "$STAGING/.background"
cp -R CC-Beeper.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Copy background image into hidden .background folder
# Background image: place docs/dmg-background.png (660x400) to enable
if [ -f "docs/dmg-background.png" ]; then
    cp docs/dmg-background.png "$STAGING/.background/dmg-background.png"
    HAS_BG=true
else
    HAS_BG=false
fi

# Create a read-write DMG for window styling
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDRW \
    -size 200m \
    "$DMG_TEMP"

# Mount the read-write DMG
MOUNT_OUTPUT=$(hdiutil attach "$DMG_TEMP" -readwrite -noverify -noautoopen)
DEV_NODE=$(echo "$MOUNT_OUTPUT" | grep -E '^/dev/' | head -1 | awk '{print $1}')
MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -E '/Volumes/' | tail -1 | awk '{print $NF}')

echo "Mounted at: $MOUNT_POINT (device: $DEV_NODE)"

# Give Finder a moment to register the volume
sleep 1

# Build AppleScript for window styling
BG_LINE=""
if [ "$HAS_BG" = true ]; then
    BG_LINE='set background picture of theViewOptions to file ".background:dmg-background.png"'
fi

# Apply window styling via AppleScript (non-fatal — may timeout in headless/CI environments)
osascript << APPLESCRIPT || echo "Warning: AppleScript styling timed out — DMG layout may need manual adjustment"
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 660, 460}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set text size of theViewOptions to 13
        ${BG_LINE}
        set position of item "CC-Beeper.app" of container window to {150, 170}
        set position of item "Applications" of container window to {410, 170}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
APPLESCRIPT

# Wait for Finder to flush .DS_Store
sleep 2

# Sync and unmount
sync
hdiutil detach "$DEV_NODE" -quiet

# Convert to compressed read-only DMG
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FINAL"

# Clean up
rm -rf "$STAGING" "$DMG_TEMP"

echo ""
echo "Created $DMG_FINAL"
echo "Volume name: $VOLUME_NAME"
echo "Users drag CC-Beeper.app to Applications to install."

# Notarize the DMG if a notary credential profile was provided.
# Example: NOTARY_PROFILE=cc-beeper-notary SIGNING_IDENTITY='Developer ID Application: ...' make dmg
if [ -n "$NOTARY_PROFILE" ]; then
    echo ""
    echo "Submitting $DMG_FINAL for notarization (profile: $NOTARY_PROFILE)..."
    xcrun notarytool submit "$DMG_FINAL" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    echo "Stapling notarization ticket to $DMG_FINAL..."
    xcrun stapler staple "$DMG_FINAL"
    echo "Stapling notarization ticket to CC-Beeper.app..."
    xcrun stapler staple CC-Beeper.app
    echo "Notarization complete."
else
    echo ""
    echo "Skipped notarization (set NOTARY_PROFILE to enable)."
fi
