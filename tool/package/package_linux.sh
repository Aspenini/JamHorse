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
"${flutter_cmd[@]}" build linux --release
cp LICENSE THIRD_PARTY_NOTICES.md build/linux/*/release/bundle/
tar -C build/linux/*/release -czf "$DIST/JamHorse-linux.tar.gz" bundle
