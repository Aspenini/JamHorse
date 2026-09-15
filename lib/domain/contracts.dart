import 'package:jamhorse/domain/models.dart';

/// Jellyfin's playback session reporting, split out so it can be buffered
/// for offline stretches without wrapping the whole gateway.
abstract interface class PlaybackReporter {
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

abstract interface class JellyfinGateway implements PlaybackReporter {
  Future<AuthSession> authenticate({
    required Uri baseUrl,
    required String username,
    required String password,
    required String deviceId,
    required bool allowPrivateHttp,
  });

  /// One page of items. [parentId] scopes to an album or playlist;
  /// [artistId] and [genreId] filter by credit and genre, which Jellyfin
  /// does not model as parents. A null [sortBy] keeps the server's natural
  /// order (playlist order for playlists).
  Future<LibraryPage> fetchLibraryPage(
    AuthSession session, {
    Set<LibraryItemType> types = const {},
    int limit = 200,
    String? parentId,
    String? artistId,
    String? genreId,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
    int startIndex = 0,
    OperationContext? context,
  });

  Future<List<LibraryItem>> fetchRecentlyPlayed(AuthSession session);

  Future<List<LyricsLine>> fetchLyrics(AuthSession session, String itemId);

  Future<void> setFavorite(AuthSession session, String itemId, bool favorite);

  Future<LibraryItem> createPlaylist(AuthSession session, String name);

  Future<void> addToPlaylist(
    AuthSession session,
    String playlistId,
    List<String> itemIds,
  );

  Uri imageUri(AuthSession session, String itemId, {int width = 600});

  Uri userImageUri(AuthSession session, {int width = 128});

  /// Negotiated (possibly transcoded) stream for playback.
  Uri streamUri(AuthSession session, LibraryItem item, {int? maxBitrate});

  /// The original file, byte for byte, for offline downloads.
  Uri downloadUri(AuthSession session, LibraryItem item);

  Map<String, String> playbackHeaders(AuthSession session);
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

  /// Updates one cached item's favorite flag without rewriting the cache.
  Future<void> setFavorite(String profileId, String itemId, bool favorite);

  Future<void> upsertItem(LibraryItem item);

  /// Playable tracks for any item, in the order Spotify would queue them.
  Future<List<LibraryItem>> tracksFor(AuthSession session, LibraryItem item);

  /// What a detail page lists: tracks for albums and playlists, albums for
  /// artists and genres.
  Future<List<LibraryItem>> childrenFor(AuthSession session, LibraryItem item);
}

abstract interface class PlaybackCoordinator {
  Stream<PlaybackSnapshot> get snapshots;

  PlaybackSnapshot get currentSnapshot;

  int? get audioSessionId;

  /// Replaces the queue. A null [shuffle] keeps the current shuffle mode.
  Future<void> load(
    AuthSession session,
    List<LibraryItem> queue, {
    int initialIndex = 0,
    bool autoPlay = true,
    bool? shuffle,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> skipNext();

  Future<void> skipPrevious();

  Future<void> skipToIndex(int index);

  Future<void> moveQueueItem(int from, int to);

  Future<void> removeQueueItemAt(int index);

  /// Inserts [items] to play immediately after the current track.
  Future<void> playNext(List<LibraryItem> items);

  /// Appends [items] after anything already queued with [playNext] or
  /// [addToQueue], ahead of the rest of the playing context.
  Future<void> addToQueue(List<LibraryItem> items);

  Future<void> setShuffle(bool enabled);

  Future<void> setRepeat(RepeatMode mode);

  Future<void> setVolume(double volume);

  Future<void> setSleepTimer(Duration? duration);

  Future<void> updateItemMetadata(LibraryItem item);

  Future<void> stop();

  /// Stops playback and forgets the queue, e.g. when the account changes.
  Future<void> reset();

  Future<void> restore(AuthSession session, List<LibraryItem> library);

  Future<void> setBrowseLibrary(AuthSession session, List<LibraryItem> library);

  /// Writes queue and position to disk now, e.g. before the app is
  /// backgrounded or closed.
  Future<void> persistNow();
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

  /// Picks up transfers that finished or failed while the app was not
  /// running.
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
    String? artistId,
    String? genreId,
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
        artistId: artistId,
        genreId: genreId,
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
