#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
cd "$ROOT"
# $FLUTTER overrides; otherwise prefer the FVM-pinned SDK when available.
if [[ -n "${FLUTTER:-}" ]]; then
  read -r -a flutter_cmd <<<"$FLUTTER"
elif command -v fvm >/dev/null 2>&1; then
  flutter_cmd=(fvm flutter)
else
  flutter_cmd=(flutter)
fi
"${flutter_cmd[@]}" build macos --release
DMG_ROOT="$(mktemp -d)"
trap 'rm -rf "$DMG_ROOT"' EXIT
cp -R "$ROOT/build/macos/Build/Products/Release/JamHorse.app" "$DMG_ROOT/"
mkdir -p "$DMG_ROOT/Licenses"
cp "$ROOT/LICENSE" "$ROOT/THIRD_PARTY_NOTICES.md" "$DMG_ROOT/Licenses/"
hdiutil create -volname JamHorse -srcfolder \
  "$DMG_ROOT" \
  -ov -format UDZO "$DIST/JamHorse-macOS.dmg"
