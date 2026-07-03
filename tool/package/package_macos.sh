#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
cd "$ROOT"
fvm flutter build macos --release
hdiutil create -volname JamHorse -srcfolder \
  "$ROOT/build/macos/Build/Products/Release/JamHorse.app" \
  -ov -format UDZO "$DIST/JamHorse-macOS.dmg"
