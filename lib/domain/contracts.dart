import 'package:jamhorse/domain/models.dart';

abstract interface class JellyfinGateway {
  Future<ServerInfo> inspectServer(Uri baseUrl);

  Future<AuthSession> authenticate({
    required Uri baseUrl,
    required String username,
    required String password,
    required String deviceId,
    required bool allowPrivateHttp,
  });

  Future<LibraryPage> fetchLibraryPage(
    AuthSession session, {
    Set<LibraryItemType> types = const {},
    int limit = 200,
    String? parentId,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
    int startIndex = 0,
    OperationContext? context,
  });

  Future<List<LibraryItem>> fetchRecentlyPlayed(AuthSession session);

  Future<List<LibraryItem>> fetchFavorites(AuthSession session);

  Future<List<LyricsLine>> fetchLyrics(AuthSession session, String itemId);

  Future<void> setFavorite(AuthSession session, String itemId, bool favorite);

  Uri imageUri(AuthSession session, String itemId, {int width = 600});

  Uri streamUri(AuthSession session, LibraryItem item, {int? maxBitrate});

  Map<String, String> playbackHeaders(AuthSession session);

  Future<void> reportPlaybackStarted(
    AuthSession session,
    LibraryItem item, {
    String? playSessionId,
  });

  Future<void> reportPlaybackProgress(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    required bool paused,
    String? playSessionId,
  });

  Future<void> reportPlaybackStopped(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    String? playSessionId,
  });
}

abstract interface class CredentialStore {
  Future<void> writeToken(String profileId, String token);

  Future<String?> readToken(String profileId);

  Future<void> deleteToken(String profileId);

  Future<void> deleteAll();
}

abstract interface class LibraryRepository {
  Future<List<LibraryItem>> readCachedLibrary(String profileId);

  Future<void> cacheLibrary(String profileId, List<LibraryItem> items);

  Future<List<LibraryItem>> synchronize(
    AuthSession session, {
    OperationContext? context,
  });

  Future<List<LibraryItem>> search(AuthSession session, String query);
}

abstract interface class PlaybackEngine {
  Stream<PlaybackSnapshot> get snapshots;

  Future<void> load(
    AuthSession session,
    List<LibraryItem> queue, {
    int initialIndex = 0,
    bool autoPlay = true,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> skipNext();

  Future<void> skipPrevious();

  Future<void> skipToIndex(int index);

  Future<void> moveQueueItem(int from, int to);

  Future<void> removeQueueItemAt(int index);

  Future<void> setShuffle(bool enabled);

  Future<void> setRepeat(RepeatMode mode);

  Future<void> setVolume(double volume);

  Future<void> setSleepTimer(Duration? duration);

  Future<void> updateItemMetadata(LibraryItem item);

  Future<void> stop();
}

abstract interface class PlaybackCoordinator implements PlaybackEngine {
  PlaybackSnapshot get currentSnapshot;
  int? get audioSessionId;

  Future<void> restore(AuthSession session, List<LibraryItem> library);

  Future<void> setBrowseLibrary(AuthSession session, List<LibraryItem> library);
}

abstract interface class DownloadManager {
  Stream<List<DownloadRecord>> get records;

  Future<void> enqueue(
    AuthSession session,
    LibraryItem item, {
    bool wifiOnly = false,
  });

  Future<void> pause(String downloadId);

  Future<void> resume(String downloadId);

  Future<void> cancel(String downloadId);

  Future<void> delete(String downloadId);

  Future<void> retry(String downloadId, AuthSession session, LibraryItem item);

  Future<void> purgeProfile(String profileId);

  Future<void> enforceStorageLimit();

  Future<void> markPlayed(String profileId, String itemId);

  Future<void> reconcile();
}

abstract interface class PlatformMediaBridge {
  PlatformCapabilities get capabilities;

  Stream<PlatformCapabilities> get capabilityChanges;

  Stream<List<CastTarget>> get castTargets;

  RemotePlaybackState get remoteSession;

  Stream<RemotePlaybackState> get remoteSessionChanges;

  Future<void> initialize();

  Future<void> showOutputPicker();

  Future<void> connectCastDevice(
    String deviceId,
    AuthSession session,
    PlaybackSnapshot snapshot,
    JellyfinGateway gateway,
  );

  Future<void> disconnectCast();

  Future<void> remotePlay();

  Future<void> remotePause();

  Future<void> remoteSeek(Duration position);

  Future<void> remoteNext();

  Future<void> remotePrevious();

  Future<void> showEqualizer({int? audioSessionId});
}

extension JellyfinGatewayPagination on JellyfinGateway {
  Future<List<LibraryItem>> fetchLibrary(
    AuthSession session, {
    Set<LibraryItemType> types = const {},
    int limit = 200,
    String? parentId,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
    OperationContext? context,
  }) async {
    context?.throwIfObsolete();
    final result = <LibraryItem>[];
    var startIndex = 0;
    while (result.length < limit) {
      final remaining = limit - result.length;
      final page = await fetchLibraryPage(
        session,
        types: types,
        limit: remaining < 500 ? remaining : 500,
        startIndex: startIndex,
        parentId: parentId,
        searchTerm: searchTerm,
        sortBy: sortBy,
        sortOrder: sortOrder,
        context: context,
      );
      context?.throwIfObsolete();
      result.addAll(page.items);
      if (page.items.isEmpty ||
          result.length >= limit ||
          (page.totalRecordCount != null &&
              startIndex + page.items.length >= page.totalRecordCount!)) {
        break;
      }
      startIndex += page.items.length;
    }
    return List.unmodifiable(result);
  }
}
