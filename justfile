# JamHorse task runner. Run `just` to list recipes.

set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Prefer the FVM-pinned SDK (.fvmrc) once `fvm install` has linked it;
# FLUTTER / DART override either choice.
fvm := path_exists(justfile_directory() / ".fvm" / "flutter_sdk")
flutter := env("FLUTTER", if fvm == "true" { "fvm flutter" } else { "flutter" })
dart := env("DART", if fvm == "true" { "fvm dart" } else { "dart" })

# Desktop device for the machine running `just`.
host := if os() == "windows" { "windows" } else if os() == "macos" { "macos" } else { "linux" }

# Optional build identifiers, read from the environment:
#   CAST_RECEIVER_APP_ID=ABCD1234 just run android
cast_app_id := env("CAST_RECEIVER_APP_ID", "")
discord_app_id := env("JAMHORSE_DISCORD_APP_ID", "")
defines := trim( \
    (if cast_app_id != "" { "--dart-define=CAST_RECEIVER_APP_ID=" + cast_app_id } else { "" }) + " " + \
    (if discord_app_id != "" { "--dart-define=JAMHORSE_DISCORD_APP_ID=" + discord_app_id } else { "" }) \
)

[private]
default:
    @just --list --unsorted

# Fetch packages and generate Drift code
[group('setup')]
setup:
    {{ flutter }} pub get
    {{ dart }} run build_runner build

# Regenerate Drift code after editing lib/data/database.dart
[group('setup')]
gen:
    {{ dart }} run build_runner build

# List devices `run` can target
[group('run')]
devices:
    {{ flutter }} devices

# Debug run; defaults to this desktop (e.g. `just run android`)
[group('run')]
run device=host *args:
    {{ flutter }} run -d {{ device }} {{ defines }} {{ args }}

# Release-mode run for profiling real performance
[group('run')]
run-release device=host *args:
    {{ flutter }} run --release -d {{ device }} {{ defines }} {{ args }}

# Static analysis
[group('quality')]
analyze:
    {{ flutter }} analyze

# Format Dart sources in place
[group('quality')]
fmt:
    {{ dart }} format lib test tool

# Fail if any Dart source is unformatted
[group('quality')]
fmt-check:
    {{ dart }} format --output=none --set-exit-if-changed lib test tool

# Run tests (e.g. `just test test/models_test.dart`)
[group('quality')]
test *args:
    {{ flutter }} test {{ args }}

# Regenerate golden images after an intentional UI change
[group('quality')]
goldens:
    {{ flutter }} test --tags golden --update-goldens

# Tests with coverage, enforcing the thresholds in tool/check_coverage.dart
[group('quality')]
coverage:
    {{ flutter }} test --coverage
    {{ dart }} run tool/check_coverage.dart

# Everything CI checks
[group('quality')]
check: fmt-check analyze test

# Release build: windows, macos, linux, apk, appbundle, ios, ipa
[group('build')]
build target=host *args:
    {{ flutter }} build {{ target }} --release {{ defines }} {{ args }}

# Android APK for sideloading
[group('build')]
apk *args: (build "apk" args)

# Packaged desktop artifact in dist/ (windows, macos, linux)
[group('build')]
package platform=host:
    {{ if platform == "windows" { "powershell.exe -NoProfile -ExecutionPolicy Bypass -File tool/package/package_windows.ps1" } else { "bash tool/package/package_" + platform + ".sh" } }}

# Type-check, test, and bundle the Google Cast receiver
[group('build')]
[working-directory('cast_receiver')]
cast-receiver:
    npm ci
    npm test
    npm run build

# Regenerate THIRD_PARTY_NOTICES.md from pubspec.lock
[group('build')]
notices:
    {{ dart }} run tool/generate_third_party_notices.dart

# Remove build output and caches
[group('setup')]
clean:
    {{ flutter }} clean
