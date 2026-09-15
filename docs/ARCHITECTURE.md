# Architecture

JamHorse uses a feature-oriented clean architecture.

- `domain/` contains immutable models and interfaces with no transport details.
- `data/` owns typed Jellyfin HTTP parsing, secure credentials, Drift
  persistence, and cache synchronization.
- `playback/` is the single source of truth for audio, queue, system controls,
  and Jellyfin playback reports.
- `downloads/` owns native background transfer state.
- `platform/` isolates optional native Cast, AirPlay, automotive, equalizer,
  SMTC, MPRIS, and Discord capabilities.
- `state/` composes services through Riverpod.
- `ui/` contains adaptive presentation only.

Access tokens never enter SQLite, artwork cache keys, application logs, URLs,
or domain objects persisted to disk. Each local account profile has isolated
cached items, downloads, queue state, reports, artwork, and credentials—even
when two accounts use the same Jellyfin server.

`JellyfinGateway` intentionally implements only the endpoints JamHorse uses.
It parses those responses into domain models and paginates with bounded page
sizes and Jellyfin's total-record count. Artists and genres are queried with
`ArtistIds` and `GenreIds`; Jellyfin does not model them as parents.

## Data flow

1. A saved local profile and token are restored from Drift and secure storage.
2. Cached library data renders immediately.
3. The library is refreshed from Jellyfin and the profile-scoped cache is
   replaced transactionally. At launch this is skipped when the cache is less
   than 15 minutes old; pull-to-refresh always syncs. Jellyfin offers no
   reliable change feed (favorites and deletions do not update
   `DateLastSaved`), so syncs are full rather than incremental.
4. Playback negotiates a Jellyfin universal audio URL and supplies auth through
   headers. Downloaded tracks play from disk; downloads fetch the original
   file with `static=true`.
5. Player state is published to Flutter and native media controls from the same
   audio handler.
6. Playback reports go through `PlaybackReporter`. `BufferedPlaybackReporter`
   queues failures in a serialized, profile-scoped retry queue that never
   blocks local playback. A queue restored at launch is not reported until the
   user presses play.

## State

- `libraryIndexProvider` derives every library view (tracks by album, liked
  songs, albums by artist, and so on) once per library change, so screens
  never filter the full library inside `build`.
- `activePlaybackProvider` merges local and Cast playback. Widgets watch the
  narrow providers derived from it (`currentTrackProvider`,
  `playbackPlayingProvider`, `playbackPositionProvider`, …) so position ticks
  rebuild only seek bars. `PlayerController` routes transport commands to
  whichever player is audible.
- `ui_state.dart` holds the desktop right panel, the saved panel widths
  (fitted to the window by `resolvePanelSizes`, which keeps the main view at
  least 360px wide and collapses the library to its rail when needed), and the
  shared "Your Library" filter, sort, and layout; `navigation_history.dart` provides desktop
  back/forward, which go_router's pop stack cannot.
- The router is built once and re-runs its redirect through
  `refreshListenable` when sign-in state changes.

## Playback queue

The queue and position are written with a throttle (at most every two
seconds), position is saved every ten seconds while playing, and everything
is flushed when the app is hidden, paused, or closed. Position-only saves do
not rewrite the queue rows.

"Play next" and "Add to queue" insert after the current track and any
earlier queued picks. While shuffled, `QueueShuffleOrder` anchors those
insertions in the play order instead of scattering them randomly.

## Persistence

The Drift schema is versioned with step-by-step migrations. Each migration is
covered by a test that builds the previous version's captured schema and
opens it with the current code.

## Security

HTTPS is the default. Private HTTP requires explicit user consent and passes
`ServerUriPolicy`; public HTTP is blocked. Dio does not automatically follow
redirects, preventing an HTTPS request from silently downgrading to HTTP.
Artwork and its extracted header colors only send auth headers to the
session's own server. Diagnostic logging redacts password, token, and API-key
patterns.
