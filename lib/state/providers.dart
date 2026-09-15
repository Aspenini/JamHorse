import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/core/server_uri_policy.dart';
import 'package:jamhorse/data/credentials.dart';
import 'package:jamhorse/data/database.dart' show AppDatabase;
import 'package:jamhorse/data/jellyfin_gateway.dart';
import 'package:jamhorse/data/repositories.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/downloads/background_download_manager.dart';
import 'package:jamhorse/platform/platform_media_bridge.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/navigation_history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final jellyfinGatewayProvider = Provider<JellyfinGateway>(
  (ref) => DioJellyfinGateway(),
);

final playbackCoordinatorProvider = Provider<PlaybackCoordinator>(
  (ref) => throw StateError('Playback coordinator was not initialized.'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => const SecureCredentialStore(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(databaseProvider),
    ref.watch(credentialStoreProvider),
  ),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => DriftLibraryRepository(
    ref.watch(databaseProvider),
    ref.watch(jellyfinGatewayProvider),
  ),
);

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = JamHorseDownloadManager(
    ref.watch(jellyfinGatewayProvider),
    ref.watch(databaseProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final platformMediaBridgeProvider = Provider<PlatformMediaBridge>((ref) {
  final bridge = NativePlatformMediaBridge();
  var previous = bridge.remoteSession;
  final remoteSubscription = bridge.remoteSessionChanges.listen((
    current,
  ) async {
    if (previous.connected && !current.connected) {
      final coordinator = ref.read(playbackCoordinatorProvider);
      await coordinator.seek(previous.position);
      await coordinator.pause();
    }
    previous = current;
  });
  unawaited(bridge.initialize());
  ref.onDispose(() async {
    await remoteSubscription.cancel();
    await bridge.dispose();
  });
  return bridge;
});

final platformCapabilitiesProvider = StreamProvider<PlatformCapabilities>((
  ref,
) {
  return ref.watch(platformMediaBridgeProvider).capabilityChanges;
});

final castTargetsProvider = StreamProvider<List<CastTarget>>((ref) {
  return ref.watch(platformMediaBridgeProvider).castTargets;
});

final remotePlaybackProvider = StreamProvider<RemotePlaybackState>((ref) {
  return ref.watch(platformMediaBridgeProvider).remoteSessionChanges;
});

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final sessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(appControllerProvider.select((state) => state.session));
});

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

/// The shared search text for the desktop top bar and the phone Search tab;
/// server searches run once typing pauses.
class SearchQueryController extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void set(String value) {
    if (value == state) return;
    state = value;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 260),
      () => ref.read(appControllerProvider.notifier).search(value),
    );
  }
}

final playbackSnapshotProvider = StreamProvider<PlaybackSnapshot>((ref) {
  final player = ref.watch(playbackCoordinatorProvider);
  return player.snapshots;
});

final downloadRecordsProvider = StreamProvider<List<DownloadRecord>>((ref) {
  return ref.watch(downloadManagerProvider).records;
});

final lyricsProvider = FutureProvider.autoDispose
    .family<List<LyricsLine>, String>((ref, itemId) {
      final session = ref.watch(sessionProvider);
      if (session == null) return Future.value(const []);
      return ref.watch(jellyfinGatewayProvider).fetchLyrics(session, itemId);
    });

/// Item ids with a completed download; playback uses the local file for
/// these instead of streaming.
final downloadedItemIdsProvider = Provider<Set<String>>((ref) {
  final records = ref.watch(downloadRecordsProvider).value ?? const [];
  final profileId = ref.watch(
    appControllerProvider.select((state) => state.session?.profile.profileId),
  );
  return {
    for (final record in records)
      if (record.profileId == profileId &&
          record.status == DownloadStatus.complete)
        record.itemId,
  };
});

/// Newest albums on the server, for the Home "Recently added" row.
final recentlyAddedProvider = FutureProvider<List<LibraryItem>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return Future.value(const []);
  return ref
      .watch(jellyfinGatewayProvider)
      .fetchLibrary(
        session,
        types: const {LibraryItemType.album},
        sortBy: 'DateCreated',
        sortOrder: 'Descending',
        limit: 20,
      );
});

/// Tracks most recently played on any Jellyfin client.
final recentlyPlayedProvider = FutureProvider<List<LibraryItem>>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return Future.value(const []);
  return ref.watch(jellyfinGatewayProvider).fetchRecentlyPlayed(session);
});

/// Albums within one genre, for the per-genre Home rows.
final genreAlbumsProvider = FutureProvider.family<List<LibraryItem>, String>((
  ref,
  genreId,
) {
  final session = ref.watch(sessionProvider);
  if (session == null) return Future.value(const []);
  return ref
      .watch(jellyfinGatewayProvider)
      .fetchLibrary(
        session,
        types: const {LibraryItemType.album},
        genreId: genreId,
        sortBy: 'Random',
        limit: 20,
      );
});

typedef ItemKey = (String id, LibraryItemType type);

/// A detail page's contents from the server: tracks for albums and
/// playlists, albums for artists and genres.
final itemChildrenProvider = FutureProvider.autoDispose
    .family<List<LibraryItem>, ItemKey>((ref, key) {
      final session = ref.watch(sessionProvider);
      if (session == null) return Future.value(const []);
      return ref
          .watch(libraryRepositoryProvider)
          .childrenFor(session, _stubItem(session, key));
    });

/// An artist's most played tracks, for the "Popular" list.
final artistTopTracksProvider = FutureProvider.autoDispose
    .family<List<LibraryItem>, String>((ref, artistId) {
      final session = ref.watch(sessionProvider);
      if (session == null) return Future.value(const []);
      return ref
          .watch(jellyfinGatewayProvider)
          .fetchLibrary(
            session,
            types: const {LibraryItemType.track},
            artistId: artistId,
            sortBy: 'PlayCount,SortName',
            sortOrder: 'Descending,Ascending',
            limit: 10,
          );
    });

LibraryItem _stubItem(AuthSession session, ItemKey key) {
  return LibraryItem(
    id: key.$1,
    profileId: session.profile.profileId,
    serverId: session.profile.serverId,
    type: key.$2,
    name: '',
  );
}

class AppState {
  const AppState({
    this.initializing = true,
    this.connecting = false,
    this.syncing = false,
    this.session,
    this.profiles = const [],
    this.library = const [],
    this.searchResults = const [],
    this.error,
  });

  final bool initializing;
  final bool connecting;
  final bool syncing;
  final AuthSession? session;
  final List<ServerProfile> profiles;
  final List<LibraryItem> library;
  final List<LibraryItem> searchResults;
  final String? error;

  bool get isAuthenticated => session != null;

  AppState copyWith({
    bool? initializing,
    bool? connecting,
    bool? syncing,
    AuthSession? session,
    bool clearSession = false,
    List<ServerProfile>? profiles,
    List<LibraryItem>? library,
    List<LibraryItem>? searchResults,
    String? error,
    bool clearError = false,
  }) {
    return AppState(
      initializing: initializing ?? this.initializing,
      connecting: connecting ?? this.connecting,
      syncing: syncing ?? this.syncing,
      session: clearSession ? null : session ?? this.session,
      profiles: profiles ?? this.profiles,
      library: library ?? this.library,
      searchResults: searchResults ?? this.searchResults,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AppController extends Notifier<AppState> {
  /// Launches within this window reuse the cached library instead of
  /// downloading it again; pull-to-refresh always syncs.
  static const autoSyncInterval = Duration(minutes: 15);

  /// Spotify-style shuffle of a very large library plays a sample.
  static const _shuffleAllLimit = 500;

  bool _restoring = false;
  int _sessionEpoch = 0;
  String? _syncingProfileId;

  JellyfinGateway get _gateway => ref.read(jellyfinGatewayProvider);
  LibraryRepository get _library => ref.read(libraryRepositoryProvider);
  ProfileRepository get _profiles => ref.read(profileRepositoryProvider);
  PlaybackCoordinator get _player => ref.read(playbackCoordinatorProvider);

  @override
  AppState build() {
    if (!_restoring) {
      _restoring = true;
      unawaited(_restore());
    }
    return const AppState();
  }

  Future<void> login({
    required String serverUrl,
    required String username,
    required String password,
    required bool allowPrivateHttp,
  }) async {
    state = state.copyWith(connecting: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('deviceId');
      deviceId ??= const Uuid().v4();
      await prefs.setString('deviceId', deviceId);
      final baseUrl = ServerUriPolicy.normalize(serverUrl);
      final session = await _gateway.authenticate(
        baseUrl: baseUrl,
        username: username,
        password: password,
        deviceId: deviceId,
        allowPrivateHttp: allowPrivateHttp,
      );
      await _profiles.save(session);
      final profiles = await _profiles.all();
      _sessionEpoch++;
      state = state.copyWith(
        session: session,
        profiles: profiles,
        connecting: false,
        library: const [],
      );
      await synchronize();
    } catch (error) {
      final message = error is DioException && error.response?.statusCode == 401
          ? 'Incorrect username or password.'
          : _friendlyError(error);
      state = state.copyWith(connecting: false, error: message);
      rethrow;
    }
  }

  /// Refreshes the library from the server. With [force] false the sync is
  /// skipped when the cache is younger than [autoSyncInterval].
  Future<void> synchronize({bool force = true}) async {
    final session = state.session;
    if (session == null || _syncingProfileId == session.profile.profileId) {
      return;
    }
    final profileId = session.profile.profileId;
    final syncKey = 'lastLibrarySync:$profileId';
    final prefs = await SharedPreferences.getInstance();
    if (!force && state.library.isNotEmpty) {
      final last = prefs.getInt(syncKey);
      if (last != null &&
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)) <
              autoSyncInterval) {
        return;
      }
    }
    if (_syncingProfileId == profileId) return;
    final epoch = _sessionEpoch;
    _syncingProfileId = profileId;
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final context = OperationContext(
        profileId: profileId,
        generation: epoch,
        isCurrentCallback: () => _isCurrent(session, epoch),
      );
      final items = await _library.synchronize(session, context: context);
      if (!_isCurrent(session, epoch)) return;
      await _player.setBrowseLibrary(session, items);
      await prefs.setInt(syncKey, DateTime.now().millisecondsSinceEpoch);
      state = state.copyWith(library: items, syncing: false);
      ref.invalidate(recentlyAddedProvider);
      ref.invalidate(recentlyPlayedProvider);
    } catch (error) {
      if (!_isCurrent(session, epoch)) return;
      final cached = await _library.readCachedLibrary(profileId);
      if (!_isCurrent(session, epoch)) return;
      state = state.copyWith(
        library: cached,
        syncing: false,
        error: cached.isEmpty ? _friendlyError(error) : null,
        clearError: cached.isNotEmpty,
      );
    } finally {
      if (_syncingProfileId == profileId) {
        _syncingProfileId = null;
        if (_isCurrent(session, epoch) && state.syncing) {
          state = state.copyWith(syncing: false);
        }
      }
    }
  }

  int _searchEpoch = 0;

  Future<void> search(String query) async {
    final session = state.session;
    final sessionEpoch = _sessionEpoch;
    final trimmed = query.trim();
    final epoch = ++_searchEpoch;
    if (session == null || trimmed.isEmpty) {
      state = state.copyWith(searchResults: const []);
      return;
    }
    final needle = trimmed.toLowerCase();
    final local = state.library
        .where(
          (item) => '${item.name} ${item.subtitle ?? ''}'
              .toLowerCase()
              .contains(needle),
        )
        .take(200)
        .toList(growable: false);
    state = state.copyWith(searchResults: local);
    try {
      final remote = await _library.search(session, trimmed);
      if (epoch == _searchEpoch && _isCurrent(session, sessionEpoch)) {
        state = state.copyWith(searchResults: remote);
      }
    } catch (_) {
      // Cached search remains available when the server is unreachable.
    }
  }

  /// Plays [selected]. A single track plays within its album, like tapping
  /// a song in Spotify; anything else plays its tracks from the top.
  Future<void> play(LibraryItem selected) async {
    final session = state.session;
    if (session == null) return;
    if (selected.type == LibraryItemType.track) {
      final album = ref
          .read(libraryIndexProvider)
          .tracksByAlbum[selected.albumId];
      final context = album != null && album.any((t) => t.id == selected.id)
          ? album
          : [selected];
      return playQueue(context, startWith: selected);
    }
    final epoch = _sessionEpoch;
    final tracks = await _library.tracksFor(session, selected);
    if (!_isCurrent(session, epoch) || tracks.isEmpty) return;
    await _player.load(session, tracks);
  }

  /// Plays an explicit list of tracks as the queue, e.g. Liked Songs or a
  /// playlist page, optionally starting from one of them. A null [shuffle]
  /// keeps the player's current shuffle mode.
  Future<void> playQueue(
    List<LibraryItem> tracks, {
    LibraryItem? startWith,
    bool? shuffle,
  }) async {
    final session = state.session;
    if (session == null || tracks.isEmpty) return;
    var index = startWith == null
        ? 0
        : tracks.indexWhere((item) => item.id == startWith.id);
    if (startWith == null && shuffle == true) {
      index = Random().nextInt(tracks.length);
    }
    await _player.load(
      session,
      tracks,
      initialIndex: index < 0 ? 0 : index,
      shuffle: shuffle,
    );
  }

  Future<void> shuffleAll() async {
    final tracks = ref.read(libraryIndexProvider).tracks.toList()..shuffle();
    await playQueue(tracks.take(_shuffleAllLimit).toList(), shuffle: true);
  }

  /// Plays all of [item]'s tracks with shuffle turned on.
  Future<void> shufflePlay(LibraryItem item) async {
    final session = state.session;
    if (session == null) return;
    final epoch = _sessionEpoch;
    final tracks = await _library.tracksFor(session, item);
    if (!_isCurrent(session, epoch) || tracks.isEmpty) return;
    await playQueue(tracks, shuffle: true);
  }

  Future<void> playNext(LibraryItem item) => _enqueue(item, next: true);

  Future<void> addToQueue(LibraryItem item) => _enqueue(item, next: false);

  Future<void> _enqueue(LibraryItem item, {required bool next}) async {
    final session = state.session;
    if (session == null) return;
    final epoch = _sessionEpoch;
    final tracks = await _library.tracksFor(session, item);
    if (!_isCurrent(session, epoch) || tracks.isEmpty) return;
    if (next) {
      await _player.playNext(tracks);
    } else {
      await _player.addToQueue(tracks);
    }
  }

  Future<void> toggleFavorite(LibraryItem item) async {
    final session = state.session;
    if (session == null) return;
    final epoch = _sessionEpoch;
    final next = !item.isFavorite;
    _setFavoriteLocally(session, item, next);
    try {
      await _gateway.setFavorite(session, item.id, next);
      if (!_isCurrent(session, epoch)) return;
      await _library.setFavorite(session.profile.profileId, item.id, next);
    } catch (error) {
      if (!_isCurrent(session, epoch)) return;
      _setFavoriteLocally(session, item, !next);
      state = state.copyWith(error: _friendlyError(error));
    }
  }

  void _setFavoriteLocally(
    AuthSession session,
    LibraryItem item,
    bool favorite,
  ) {
    final library = List<LibraryItem>.unmodifiable([
      for (final entry in state.library)
        entry.id == item.id ? entry.copyWith(isFavorite: favorite) : entry,
    ]);
    state = state.copyWith(library: library);
    unawaited(_player.setBrowseLibrary(session, library));
    unawaited(_player.updateItemMetadata(item.copyWith(isFavorite: favorite)));
  }

  /// Creates an empty Jellyfin playlist and adds it to the library.
  Future<LibraryItem?> createPlaylist(String name) async {
    final session = state.session;
    final trimmed = name.trim();
    if (session == null || trimmed.isEmpty) return null;
    final epoch = _sessionEpoch;
    final playlist = await _gateway.createPlaylist(session, trimmed);
    if (!_isCurrent(session, epoch)) return null;
    await _library.upsertItem(playlist);
    state = state.copyWith(
      library: List.unmodifiable([...state.library, playlist]),
    );
    return playlist;
  }

  /// Adds [item] (or all of its tracks) to [playlist]; returns how many
  /// tracks were added.
  Future<int> addToPlaylist(LibraryItem playlist, LibraryItem item) async {
    final session = state.session;
    if (session == null) return 0;
    final tracks = await _library.tracksFor(session, item);
    await _gateway.addToPlaylist(
      session,
      playlist.id,
      tracks.map((track) => track.id).toList(growable: false),
    );
    ref.invalidate(itemChildrenProvider((playlist.id, playlist.type)));
    return tracks.length;
  }

  Future<void> download(LibraryItem item, {bool? wifiOnly}) async {
    final session = state.session;
    if (session == null) return;
    final epoch = _sessionEpoch;
    final prefs = await SharedPreferences.getInstance();
    final requiresWifi =
        wifiOnly ?? prefs.getBool('wifiOnlyDownloads') ?? false;
    if (!_isCurrent(session, epoch)) return;
    final manager = ref.read(downloadManagerProvider);
    final tracks = await _library.tracksFor(session, item);
    for (final track in tracks) {
      if (!_isCurrent(session, epoch)) return;
      await manager.enqueue(session, track, wifiOnly: requiresWifi);
    }
  }

  Future<void> downloadAll(List<LibraryItem> tracks, {bool? wifiOnly}) async {
    for (final track in tracks) {
      await download(track, wifiOnly: wifiOnly);
    }
  }

  Future<void> switchProfile(ServerProfile profile) async {
    if (state.session?.profile.profileId == profile.profileId) return;
    _sessionEpoch++;
    _searchEpoch++;
    await _player.reset();
    ref.read(navigationHistoryProvider.notifier).reset();
    final session = await _profiles.restore(profile);
    if (session == null) {
      state = state.copyWith(
        clearSession: true,
        library: const [],
        error: 'Sign in to ${profile.name} again.',
      );
      return;
    }
    final cached = await _library.readCachedLibrary(profile.profileId);
    state = state.copyWith(session: session, library: cached, clearError: true);
    await _player.restore(session, cached);
    await _profiles.save(session);
    await synchronize(force: false);
  }

  Future<void> logout({
    bool forgetServer = false,
    bool preserveCredential = false,
  }) async {
    final session = state.session;
    _sessionEpoch++;
    _searchEpoch++;
    await _player.reset();
    if (session != null && forgetServer) {
      await ref
          .read(downloadManagerProvider)
          .purgeProfile(session.profile.profileId);
      await _profiles.remove(session.profile.profileId);
    } else if (session != null && !preserveCredential) {
      await _profiles.signOut(session.profile.profileId);
    }
    final profiles = await _profiles.all();
    state = state.copyWith(
      clearSession: true,
      profiles: profiles,
      library: const [],
      searchResults: const [],
      clearError: true,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> _restore() async {
    try {
      final profiles = await _profiles.all();
      if (profiles.isEmpty) {
        state = state.copyWith(initializing: false, profiles: profiles);
        return;
      }
      final session = await _profiles.restore(profiles.first);
      if (session == null) {
        state = state.copyWith(initializing: false, profiles: profiles);
        return;
      }
      final cached = await _library.readCachedLibrary(
        session.profile.profileId,
      );
      state = state.copyWith(
        initializing: false,
        session: session,
        profiles: profiles,
        library: cached,
      );
      await _player.restore(session, cached);
      unawaited(synchronize(force: false));
    } catch (error) {
      state = state.copyWith(initializing: false, error: _friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      return switch (error.response?.statusCode) {
        401 => 'Your Jellyfin session expired. Sign in again.',
        403 => 'Your Jellyfin account is not allowed to do that.',
        final int status => 'Jellyfin returned an error ($status).',
        null => switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout =>
            'The server took too long to respond.',
          DioExceptionType.badCertificate =>
            "The server's TLS certificate is not trusted.",
          _ => "Can't reach the server. Check your connection.",
        },
      };
    }
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('FormatException: ', '');
  }

  bool _isCurrent(AuthSession session, int epoch) {
    return epoch == _sessionEpoch &&
        state.session?.profile.profileId == session.profile.profileId;
  }
}
