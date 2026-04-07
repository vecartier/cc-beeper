#!/bin/bash
set -e

cd "$(dirname "$0")"

# Fetch latest from remote
git fetch origin main --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "CC-Beeper is up to date."
    exit 0
fi

echo "Update available — pulling and rebuilding..."
git pull --quiet origin main

./build.sh

# Stop running instance if any
pkill -x CC-Beeper 2>/dev/null || true
sleep 0.5

# Install to /Applications
rm -rf /Applications/CC-Beeper.app
cp -R CC-Beeper.app /Applications/

# Relaunch
open /Applications/CC-Beeper.app

echo "CC-Beeper updated and relaunched."
