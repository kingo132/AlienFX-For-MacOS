#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h}"
cd "$ROOT"

xcodebuild \
  -project AlienFxTest.xcodeproj \
  -scheme AlienFxTest \
  -configuration Release \
  -derivedDataPath "$ROOT/build" \
  build

APP="$ROOT/build/Build/Products/Release/AlienFX.app"
echo
echo "Build complete:"
echo "$APP"
echo
echo "Move AlienFX.app to /Applications before enabling Launch at Login."
