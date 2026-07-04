# Architecture

JamHorse uses a feature-oriented clean architecture.

- `domain/` contains immutable models and interfaces with no transport details.
- `data/` owns typed Jellyfin HTTP parsing, secure credentials, Drift
  persistence, and cache synchronization.
- `playback/` is the single source of truth for audio, queue, system controls,
  and Jellyfin playback reports.
- `downloads/` owns native background transfer state.
- `platform/` isolates optional native Cast, AirPlay, automotive, equalizer,
  SMTC, and MPRIS capabilities.
- `state/` composes services through Riverpod.
- `ui/` contains adaptive presentation only.

Access tokens never enter SQLite, artwork cache keys, application logs, URLs,
or domain objects persisted to disk. Each local account profile has isolated
cached items, downloads, queue state, reports, artwork, and credentials—even
when two accounts use the same Jellyfin server.

`JellyfinGateway` intentionally implements only the endpoints JamHorse uses.
It parses those responses into domain models and paginates with bounded page
sizes and Jellyfin's total-record count.

## Data flow

1. A saved local profile and token are restored from Drift and secure storage.
2. Cached library data renders immediately.
3. Foreground synchronization refreshes Jellyfin items and replaces the
   profile-scoped cache transactionally.
4. Playback negotiates a Jellyfin universal audio URL and supplies auth through
   headers.
5. Player state is published to Flutter and native media controls from the same
   audio handler.
6. Playback reports are sent to Jellyfin; failures enter a serialized,
   profile-scoped retry queue and never block local playback.

## Security

HTTPS is the default. Private HTTP requires explicit user consent and passes
`ServerUriPolicy`; public HTTP is blocked. Dio does not automatically follow
redirects, preventing an HTTPS request from silently downgrading to HTTP.
Diagnostic logging redacts password, token, and API-key patterns.
