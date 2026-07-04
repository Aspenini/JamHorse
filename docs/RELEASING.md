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

Protected release jobs must fail when production signing or notarization
credentials are absent. Ordinary CI builds unsigned artifacts only for
five-platform quality and smoke testing.

A production HTTPS Cast receiver URL and registered Cast application ID are
mandatory release inputs. HTTP Jellyfin profiles are never Cast-eligible.

Apple CarPlay browsing requires a CarPlay audio-app entitlement issued by
Apple. Normal lock-screen, Bluetooth, headset, and Now Playing integration does
not depend on that entitlement.

For an approved build, set the protected `CARPLAY_ENABLED=true` secret and use
an entitlement-enabled provisioning profile. The release workflow then copies
`ios/Runner/CarPlay.entitlements.example` into the signed target and enables
CarPlay discovery at runtime. Ordinary builds compile with CarPlay hidden.
