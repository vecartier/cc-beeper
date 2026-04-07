#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Build the app first
./build.sh

echo "Creating DMG with create-dmg..."

rm -f CC-Beeper.dmg

# Stage app in temp directory (create-dmg expects a source folder)
STAGING="/tmp/cc-beeper-dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R CC-Beeper.app "$STAGING/"

create-dmg \
    --volname "CC-Beeper" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 128 \
    --icon "CC-Beeper.app" 180 170 \
    --app-drop-link 480 170 \
    --hide-extension "CC-Beeper.app" \
    --no-internet-enable \
    CC-Beeper.dmg \
    "$STAGING"

rm -rf "$STAGING"

echo ""
echo "Created CC-Beeper.dmg"

# Notarize if profile provided
if [ -n "$NOTARY_PROFILE" ]; then
    echo ""
    echo "Submitting CC-Beeper.dmg for notarization (profile: $NOTARY_PROFILE)..."
    xcrun notarytool submit CC-Beeper.dmg \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    xcrun stapler staple CC-Beeper.dmg
    xcrun stapler staple CC-Beeper.app
    echo "Notarization complete."
else
    echo ""
    echo "Skipped notarization (set NOTARY_PROFILE to enable)."
fi
