#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
cd "$ROOT"
fvm flutter build macos --release
DMG_ROOT="$(mktemp -d)"
trap 'rm -rf "$DMG_ROOT"' EXIT
cp -R "$ROOT/build/macos/Build/Products/Release/JamHorse.app" "$DMG_ROOT/"
mkdir -p "$DMG_ROOT/Licenses"
cp "$ROOT/LICENSE" "$ROOT/THIRD_PARTY_NOTICES.md" "$DMG_ROOT/Licenses/"
hdiutil create -volname JamHorse -srcfolder \
  "$DMG_ROOT" \
  -ov -format UDZO "$DIST/JamHorse-macOS.dmg"
