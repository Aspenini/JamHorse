import 'dart:async';

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

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// Whether the Now Playing side panel is slid in, Spotify style.
final nowPlayingViewProvider = NotifierProvider<NowPlayingViewController, bool>(
  NowPlayingViewController.new,
);

class NowPlayingViewController extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool visible) => state = visible;
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
      final session = ref.watch(
        appControllerProvider.select((state) => state.session),
      );
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
  final session = ref.watch(
    appControllerProvider.select((state) => state.session),
  );
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

/// Albums within one genre, for the per-genre Home rows.
final genreAlbumsProvider = FutureProvider.family<List<LibraryItem>, String>((
  ref,
  genreId,
) {
  final session = ref.watch(
    appControllerProvider.select((state) => state.session),
  );
  if (session == null) return Future.value(const []);
  return ref
      .watch(jellyfinGatewayProvider)
      .fetchLibrary(
        session,
        types: const {LibraryItemType.album},
        parentId: genreId,
        limit: 20,
      );
});

/// Album names by id, for the ALBUM column in track tables.
final albumNamesProvider = Provider<Map<String, String>>((ref) {
  final library = ref.watch(
    appControllerProvider.select((state) => state.library),
  );
  return {
    for (final item in library)
      if (item.type == LibraryItemType.album) item.id: item.name,
  };
});

/// Tracks inside an album or playlist, fetched from the server in play
/// order. Used by detail views whose children are not in the synced
/// library snapshot (playlist entries in particular).
final childrenProvider = FutureProvider.autoDispose
    .family<List<LibraryItem>, String>((ref, parentId) {
      final session = ref.watch(
        appControllerProvider.select((state) => state.session),
      );
      if (session == null) return Future.value(const []);
      return ref
          .watch(jellyfinGatewayProvider)
          .fetchLibrary(
            session,
            types: const {LibraryItemType.track},
            parentId: parentId,
            sortBy: 'ParentIndexNumber,IndexNumber,SortName',
            limit: 5000,
          );
    });

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
      state = state.copyWith(connecting: false, error: _friendlyError(error));
      rethrow;
    }
  }

  Future<void> synchronize() async {
    final session = state.session;
    if (session == null || _syncingProfileId == session.profile.profileId) {
      return;
    }
    final epoch = _sessionEpoch;
    _syncingProfileId = session.profile.profileId;
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final context = OperationContext(
        profileId: session.profile.profileId,
        generation: epoch,
        isCurrentCallback: () => _isCurrent(session, epoch),
      );
      final items = await _library.synchronize(session, context: context);
      if (!_isCurrent(session, epoch)) return;
      await _player.setBrowseLibrary(session, items);
      state = state.copyWith(library: items, syncing: false);
    } catch (error) {
      if (!_isCurrent(session, epoch)) return;
      final cached = await _library.readCachedLibrary(
        session.profile.profileId,
      );
      if (!_isCurrent(session, epoch)) return;
      state = state.copyWith(
        library: cached,
        syncing: false,
        error: cached.isEmpty ? _friendlyError(error) : null,
        clearError: cached.isNotEmpty,
      );
    } finally {
      if (_syncingProfileId == session.profile.profileId) {
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
    final local = state.library
        .where((item) {
          final haystack = '${item.name} ${item.subtitle ?? ''}'.toLowerCase();
          return haystack.contains(trimmed.toLowerCase());
        })
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

  Future<void> play(LibraryItem selected) async {
    final session = state.session;
    if (session == null) return;
    final epoch = _sessionEpoch;
    var tracks = <LibraryItem>[];
    if (selected.type == LibraryItemType.track) {
      tracks = state.library
          .where((item) => item.type == LibraryItemType.track)
          .toList(growable: false);
      if (!tracks.any((item) => item.id == selected.id)) {
        tracks = [selected, ...tracks];
      }
    } else {
      tracks = await _gateway.fetchLibrary(
        session,
        types: const {LibraryItemType.track},
        parentId: selected.id,
        sortBy: 'ParentIndexNumber,IndexNumber,SortName',
        limit: 5000,
      );
      if (!_isCurrent(session, epoch)) return;
    }
    if (tracks.isEmpty) return;
    final index = selected.type == LibraryItemType.track
        ? tracks.indexWhere((item) => item.id == selected.id)
        : 0;
    await _player.load(session, tracks, initialIndex: index < 0 ? 0 : index);
  }

  /// Plays an explicit list of tracks as the queue, e.g. Liked Songs or a
  /// playlist page, optionally starting from one of them.
  Future<void> playQueue(
    List<LibraryItem> tracks, {
    LibraryItem? startWith,
    bool shuffle = false,
  }) async {
    final session = state.session;
    if (session == null || tracks.isEmpty) return;
    final queue = shuffle ? (tracks.toList()..shuffle()) : tracks;
    final index = startWith == null
        ? 0
        : queue.indexWhere((item) => item.id == startWith.id);
    await _player.load(session, queue, initialIndex: index < 0 ? 0 : index);
  }

  Future<void> shuffleAll() async {
    final session = state.session;
    if (session == null) return;
    final tracks =
        state.library
            .where((item) => item.type == LibraryItemType.track)
            .toList()
          ..shuffle();
    if (tracks.isEmpty) return;
    await _player.load(session, tracks);
  }

  Future<void> toggleFavorite(LibraryItem item) async {
    final session = state.session;
    if (session == null) return;
    final epoch = _sessionEpoch;
    final next = !item.isFavorite;
    final optimistic = state.library
        .map(
          (entry) =>
              entry.id == item.id ? entry.copyWith(isFavorite: next) : entry,
        )
        .toList(growable: false);
    state = state.copyWith(library: optimistic);
    await _player.setBrowseLibrary(session, optimistic);
    try {
      await _gateway.setFavorite(session, item.id, next);
      if (!_isCurrent(session, epoch)) return;
      await _library.cacheLibrary(session.profile.profileId, optimistic);
      final updated = optimistic.firstWhere(
        (entry) => entry.id == item.id,
        orElse: () => item.copyWith(isFavorite: next),
      );
      await _player.updateItemMetadata(updated);
    } catch (error) {
      if (!_isCurrent(session, epoch)) return;
      state = state.copyWith(
        library: state.library
            .map(
              (entry) => entry.id == item.id
                  ? entry.copyWith(isFavorite: !next)
                  : entry,
            )
            .toList(growable: false),
        error: _friendlyError(error),
      );
      await _player.setBrowseLibrary(session, state.library);
      for (final restored in state.library) {
        if (restored.id == item.id) {
          await _player.updateItemMetadata(restored);
          break;
        }
      }
    }
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
    if (item.type == LibraryItemType.track) {
      return manager.enqueue(session, item, wifiOnly: requiresWifi);
    }
    final tracks = await _gateway.fetchLibrary(
      session,
      types: const {LibraryItemType.track},
      parentId: item.id,
      limit: 5000,
    );
    if (!_isCurrent(session, epoch)) return;
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
    await _player.stop();
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
    await synchronize();
  }

  Future<void> logout({
    bool forgetServer = false,
    bool preserveCredential = false,
  }) async {
    final session = state.session;
    _sessionEpoch++;
    _searchEpoch++;
    await _player.stop();
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
      unawaited(synchronize());
    } catch (error) {
      state = state.copyWith(initializing: false, error: _friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString();
    return value
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('FormatException: ', '');
  }

  bool _isCurrent(AuthSession session, int epoch) {
    return epoch == _sessionEpoch &&
        state.session?.profile.profileId == session.profile.profileId;
  }
}
