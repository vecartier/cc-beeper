#!/bin/bash
set -e

cd "$(dirname "$0")"

# Build the app first
./build.sh

echo "Creating DMG..."

# Clean up any previous staging
rm -rf /tmp/cc-beeper-dmg CC-Beeper.dmg

# Stage the DMG contents
mkdir -p /tmp/cc-beeper-dmg
cp -R CC-Beeper.app /tmp/cc-beeper-dmg/
ln -s /Applications /tmp/cc-beeper-dmg/Applications

# Create compressed DMG
hdiutil create \
    -volname "CC-Beeper" \
    -srcfolder /tmp/cc-beeper-dmg \
    -ov \
    -format UDZO \
    CC-Beeper.dmg

# Clean up staging
rm -rf /tmp/cc-beeper-dmg

echo ""
echo "Created CC-Beeper.dmg"
echo "Share it — users just drag CC-Beeper.app to Applications."
