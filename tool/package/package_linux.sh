#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"
cd "$ROOT"
fvm flutter build linux --release
cp LICENSE THIRD_PARTY_NOTICES.md build/linux/*/release/bundle/
tar -C build/linux/*/release -czf "$DIST/JamHorse-linux.tar.gz" bundle
