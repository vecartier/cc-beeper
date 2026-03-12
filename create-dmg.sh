#!/bin/bash
set -e

cd "$(dirname "$0")"

# Build the app first
./build.sh

echo "Creating DMG..."

# Clean up any previous staging
rm -rf /tmp/claumagotchi-dmg Claumagotchi.dmg

# Stage the DMG contents
mkdir -p /tmp/claumagotchi-dmg
cp -R Claumagotchi.app /tmp/claumagotchi-dmg/
ln -s /Applications /tmp/claumagotchi-dmg/Applications

# Create compressed DMG
hdiutil create \
    -volname "Claumagotchi" \
    -srcfolder /tmp/claumagotchi-dmg \
    -ov \
    -format UDZO \
    Claumagotchi.dmg

# Clean up staging
rm -rf /tmp/claumagotchi-dmg

echo ""
echo "Created Claumagotchi.dmg"
echo "Share it — users just drag Claumagotchi.app to Applications."
