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
if [ -f "docs/dmg-background.png" ]; then
    cp docs/dmg-background.png "$STAGING/.background/dmg-background.png"
else
    echo "Warning: docs/dmg-background.png not found — DMG will have no background"
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

# Apply window styling via AppleScript
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 760, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background picture of theViewOptions to file ".background:dmg-background.png"
        set position of item "CC-Beeper.app" of container window to {180, 200}
        set position of item "Applications" of container window to {480, 200}
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
