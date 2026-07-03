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

final platformMediaBridgeProvider = Provider<PlatformMediaBridge>(
  (ref) => const NativePlatformMediaBridge(),
);

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final playbackSnapshotProvider = StreamProvider<PlaybackSnapshot>((ref) {
  final player = ref.watch(playbackCoordinatorProvider);
  return player.snapshots;
});

final downloadRecordsProvider = StreamProvider<List<DownloadRecord>>((ref) {
  return ref.watch(downloadManagerProvider).records;
});

final lyricsProvider =
    FutureProvider.autoDispose.family<List<LyricsLine>, String>((
      ref,
      itemId,
    ) {
      final session = ref.watch(
        appControllerProvider.select((state) => state.session),
      );
      if (session == null) return Future.value(const []);
      return ref.watch(jellyfinGatewayProvider).fetchLyrics(session, itemId);
    });

/// Newest albums on the server, for the Home "Recently added" row.
final recentlyAddedProvider = FutureProvider<List<LibraryItem>>((ref) {
  final session = ref.watch(
    appControllerProvider.select((state) => state.session),
  );
  if (session == null) return Future.value(const []);
  return ref.watch(jellyfinGatewayProvider).fetchLibrary(
    session,
    types: const {LibraryItemType.album},
    sortBy: 'DateCreated',
    sortOrder: 'Descending',
    limit: 20,
  );
});

/// Albums within one genre, for the per-genre Home rows.
final genreAlbumsProvider =
    FutureProvider.family<List<LibraryItem>, String>((ref, genreId) {
      final session = ref.watch(
        appControllerProvider.select((state) => state.session),
      );
      if (session == null) return Future.value(const []);
      return ref.watch(jellyfinGatewayProvider).fetchLibrary(
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
final childrenProvider =
    FutureProvider.autoDispose.family<List<LibraryItem>, String>((
      ref,
      parentId,
    ) {
      final session = ref.watch(
        appControllerProvider.select((state) => state.session),
      );
      if (session == null) return Future.value(const []);
      return ref.watch(jellyfinGatewayProvider).fetchLibrary(
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

  JellyfinGateway get _gateway => ref.read(jellyfinGatewayProvider);
  LibraryRepository get _library => ref.read(libraryRepositoryProvider);
  ProfileRepository get _profiles => ref.read(profileRepositoryProvider);
  PlaybackCoordinator get _player =>
      ref.read(playbackCoordinatorProvider);

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
    state = state.copyWith(
      connecting: true,
      clearError: true,
    );
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
      state = state.copyWith(
        session: session,
        profiles: profiles,
        connecting: false,
        library: const [],
      );
      await synchronize();
    } catch (error) {
      state = state.copyWith(
        connecting: false,
        error: _friendlyError(error),
      );
      rethrow;
    }
  }

  Future<void> synchronize() async {
    final session = state.session;
    if (session == null || state.syncing) return;
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final items = await _library.synchronize(session);
      state = state.copyWith(library: items, syncing: false);
    } catch (error) {
      final cached = await _library.readCachedLibrary(session.profile.id);
      state = state.copyWith(
        library: cached,
        syncing: false,
        error: cached.isEmpty ? _friendlyError(error) : null,
        clearError: cached.isNotEmpty,
      );
    }
  }

  int _searchEpoch = 0;

  Future<void> search(String query) async {
    final session = state.session;
    final trimmed = query.trim();
    final epoch = ++_searchEpoch;
    if (session == null || trimmed.isEmpty) {
      state = state.copyWith(searchResults: const []);
      return;
    }
    final local = state.library.where((item) {
      final haystack = '${item.name} ${item.subtitle ?? ''}'.toLowerCase();
      return haystack.contains(trimmed.toLowerCase());
    }).toList(growable: false);
    state = state.copyWith(searchResults: local);
    try {
      final remote = await _library.search(session, trimmed);
      if (epoch == _searchEpoch) {
        state = state.copyWith(searchResults: remote);
      }
    } catch (_) {
      // Cached search remains available when the server is unreachable.
    }
  }

  Future<void> play(LibraryItem selected) async {
    final session = state.session;
    if (session == null) return;
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
    }
    if (tracks.isEmpty) return;
    final index = selected.type == LibraryItemType.track
        ? tracks.indexWhere((item) => item.id == selected.id)
        : 0;
    await _player.load(
      session,
      tracks,
      initialIndex: index < 0 ? 0 : index,
    );
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
    final tracks = state.library
        .where((item) => item.type == LibraryItemType.track)
        .toList()
      ..shuffle();
    if (tracks.isEmpty) return;
    await _player.load(session, tracks);
  }

  Future<void> toggleFavorite(LibraryItem item) async {
    final session = state.session;
    if (session == null) return;
    final next = !item.isFavorite;
    final optimistic = state.library
        .map(
          (entry) => entry.id == item.id
              ? entry.copyWith(isFavorite: next)
              : entry,
        )
        .toList(growable: false);
    state = state.copyWith(library: optimistic);
    try {
      await _gateway.setFavorite(session, item.id, next);
      await _library.cacheLibrary(session.profile.id, optimistic);
    } catch (error) {
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
    }
  }

  Future<void> download(LibraryItem item, {bool? wifiOnly}) async {
    final session = state.session;
    if (session == null) return;
    final prefs = await SharedPreferences.getInstance();
    final requiresWifi =
        wifiOnly ?? prefs.getBool('wifiOnlyDownloads') ?? false;
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
    for (final track in tracks) {
      await manager.enqueue(session, track, wifiOnly: requiresWifi);
    }
  }

  Future<void> downloadAll(
    List<LibraryItem> tracks, {
    bool? wifiOnly,
  }) async {
    for (final track in tracks) {
      await download(track, wifiOnly: wifiOnly);
    }
  }

  Future<void> switchProfile(ServerProfile profile) async {
    if (state.session?.profile.id == profile.id) return;
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
    final cached = await _library.readCachedLibrary(profile.id);
    state = state.copyWith(
      session: session,
      library: cached,
      clearError: true,
    );
    await _profiles.save(session);
    await synchronize();
  }

  Future<void> logout({bool forgetServer = false}) async {
    final session = state.session;
    await _player.stop();
    if (session != null && forgetServer) {
      await _profiles.remove(session.profile.id);
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
      final cached = await _library.readCachedLibrary(session.profile.id);
      state = state.copyWith(
        initializing: false,
        session: session,
        profiles: profiles,
        library: cached,
      );
      unawaited(synchronize());
    } catch (error) {
      state = state.copyWith(
        initializing: false,
        error: _friendlyError(error),
      );
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString();
    return value
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('FormatException: ', '');
  }
}
