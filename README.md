# JamHorse

JamHorse is a dark-first Jellyfin music player for Android, iOS, macOS,
Windows, and Linux. It is built with Flutter and licensed under GPLv3.

![JamHorse icon](assets/icons/jamhorse-512.png)

## Included

- Multi-server Jellyfin login with secure token storage
- Cache-first albums, artists, songs, playlists, genres, favorites, and search
- Native background audio, queue, shuffle, repeat, seek, system controls,
  playback reporting, synchronized lyrics, and a sleep timer
- Background downloads with pause, resume, retry, Wi-Fi constraints, and
  private application storage
- Adaptive mobile, tablet, and desktop layouts
- Platform capability bridge for Cast, AirPlay, automotive controls, desktop
  media sessions, and equalizer support
- Pinned Jellyfin 10.11 OpenAPI client isolated behind domain interfaces
- Redacted local diagnostics with no analytics or third-party music services

## Development

Requirements: FVM, Xcode/CocoaPods for Apple builds, Android Studio/JDK 17 for
Android, Visual Studio C++ tools for Windows, and GTK/libsecret/mpv development
packages for Linux.

```sh
fvm install
fvm flutter pub get
fvm dart run build_runner build
fvm flutter run
```

The application identifier is `com.jamhorse.app`. Android supports API 23+,
iOS supports 14+, and macOS supports 12+.

Plain HTTP is accepted only when the user explicitly enables it for localhost,
`.local`, link-local, or private IP addresses. Invalid TLS certificates and
public HTTP endpoints are rejected.

## Quality checks

```sh
fvm flutter analyze
fvm flutter test
fvm flutter build macos --release
```

See [architecture](docs/ARCHITECTURE.md) and
[release instructions](docs/RELEASING.md) for implementation and packaging
details.
