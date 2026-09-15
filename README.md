# JamHorse

JamHorse is a dark-first Jellyfin music player for Android, iOS, macOS,
Windows, and Linux, designed to feel like Spotify. It is built with Flutter
and licensed under GPLv3.

![JamHorse icon](assets/icons-output/web/icon-512.png)

## Included

- Spotify-style three-panel desktop layout (Your Library, content, and a
  Now Playing / Queue / Lyrics panel) and phone layout with Home, Search, and
  Your Library tabs
- Multi-server Jellyfin login with secure token storage
- Cache-first albums, artists, songs, playlists, genres, and liked songs
- Grouped search with a top result, and "Browse all" genre tiles
- Right-click and long-press menus: play next, add to queue, add to
  playlist, like, download, go to album or artist
- Playlist creation, shuffle-aware queue with drag-to-reorder, synced
  lyrics with tap-to-seek, and a sleep timer
- Native background audio, system media controls, and playback reporting
  that survives offline stretches
- Background downloads of original files with pause, resume, retry, Wi-Fi
  constraints, and a storage limit
- Cast, AirPlay, automotive controls, desktop media sessions, equalizer
  support, and Discord Rich Presence
- Redacted local diagnostics with no analytics or third-party music services

## Development

Requirements: Flutter 3.47.4 (pinned in `.fvmrc`; [FVM](https://fvm.app) is
used automatically when installed), [just](https://github.com/casey/just),
Xcode/CocoaPods for Apple builds, Android Studio/JDK 17 for Android, Visual
Studio C++ tools for Windows, and GTK/libsecret/mpv development packages for
Linux.

```sh
just setup          # fetch packages and generate Drift code
just run            # run on this desktop
just run android    # or any device listed by `just devices`
```

Run `just` to see every recipe, including `build`, `apk`, `package`, and
`cast-receiver`. Build identifiers such as `CAST_RECEIVER_APP_ID` and
`JAMHORSE_DISCORD_APP_ID` are read from the environment.

The application identifier is `com.aspenini.jamhorse`. Android supports API 23+,
iOS supports 14+, and macOS supports 12+.

Plain HTTP is accepted only when the user explicitly enables it for literal
loopback, link-local, RFC1918, or ULA addresses. Invalid TLS certificates,
local DNS names, and public HTTP endpoints are rejected.

## Quality checks

```sh
just check      # format check, analyze, and all tests
just goldens    # re-render golden images after an intentional UI change
just coverage   # tests with the coverage thresholds from tool/check_coverage.dart
```

CI runs the same checks, except golden images, which depend on the host OS.

See [architecture](docs/ARCHITECTURE.md) and
[release instructions](docs/RELEASING.md) for implementation and packaging
details.
