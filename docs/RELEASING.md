# Releasing

1. Update `version` in `pubspec.yaml`.
2. Run analysis, tests, and all available platform builds.
3. Build artifacts with the scripts in `tool/package/`.
4. Sign artifacts only through environment-provided credentials.
5. Include `LICENSE` and `THIRD_PARTY_NOTICES.md` with every desktop package.

## Signing inputs

- Android: `android/key.properties` and a keystore
- iOS: Apple development team and provisioning profile
- macOS: Developer ID Application identity and notarization credentials
- Windows: code-signing certificate available to `signtool`
- Linux: optional repository/GPG signing key

Without signing credentials, CI emits unsigned APK, iOS archive, DMG, Windows
ZIP, Linux tarball, and Flatpak manifest inputs suitable for local testing.

Apple CarPlay browsing requires a CarPlay audio-app entitlement issued by
Apple. Normal lock-screen, Bluetooth, headset, and Now Playing integration does
not depend on that entitlement.
