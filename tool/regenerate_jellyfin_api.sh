#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT/tool/openapi/jellyfin-10.11.json"
GENERATOR_VERSION="7.16.0"
JAR="${HOME}/Library/Caches/jamhorse-tools/openapi-generator-cli-${GENERATOR_VERSION}.jar"

mkdir -p "$(dirname "$SPEC")" "$(dirname "$JAR")"
curl -L --fail --silent --show-error \
  https://api.jellyfin.org/openapi/jellyfin-openapi-stable.json \
  -o "$SPEC"
curl -L --fail --silent --show-error \
  "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/${GENERATOR_VERSION}/openapi-generator-cli-${GENERATOR_VERSION}.jar" \
  -o "$JAR"

java -jar "$JAR" generate \
  -i "$SPEC" \
  -g dart-dio \
  -o "$ROOT/packages/jellyfin_api" \
  --additional-properties=pubName=jellyfin_api,pubVersion=10.11.0,useEnumExtension=true \
  --global-property=apiDocs=false,modelDocs=false,apiTests=false,modelTests=false

(
  cd "$ROOT/packages/jellyfin_api"
  fvm dart pub get
  fvm dart run build_runner build
)
