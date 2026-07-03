# Architecture

JamHorse uses a feature-oriented clean architecture.

- `domain/` contains immutable models and interfaces with no transport details.
- `data/` owns Jellyfin HTTP, secure credentials, Drift persistence, generated
  API adaptation, and cache synchronization.
- `playback/` is the single source of truth for audio, queue, system controls,
  and Jellyfin playback reports.
- `downloads/` owns native background transfer state.
- `platform/` isolates optional native Cast, AirPlay, automotive, equalizer,
  SMTC, and MPRIS capabilities.
- `state/` composes services through Riverpod.
- `ui/` contains adaptive presentation only.

Access tokens never enter SQLite, artwork cache keys, application logs, or
domain objects persisted to disk. Each server has isolated cached items,
downloads, queue state, and reports.

The generated package under `packages/jellyfin_api` is pinned from the official
Jellyfin 10.11 OpenAPI document. UI and playback code depend on
`JellyfinGateway`, not generated DTOs. Regenerate it with:

```sh
tool/regenerate_jellyfin_api.sh
```

## Data flow

1. A saved server profile and token are restored from Drift and secure storage.
2. Cached library data renders immediately.
3. Foreground synchronization refreshes Jellyfin items and replaces the
   server-scoped cache transactionally.
4. Playback negotiates a Jellyfin universal audio URL and supplies auth through
   headers.
5. Player state is published to Flutter and native media controls from the same
   audio handler.
6. Playback reports are sent to Jellyfin; failures are safe to retry.

## Security

HTTPS is the default. Private HTTP requires explicit user consent and passes
`ServerUriPolicy`; public HTTP is blocked. Dio does not automatically follow
redirects, preventing an HTTPS request from silently downgrading to HTTP.
Diagnostic logging redacts password, token, and API-key patterns.
