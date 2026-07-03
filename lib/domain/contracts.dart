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

  Future<List<LibraryItem>> fetchLibrary(
    AuthSession session, {
    Set<LibraryItemType> types = const {},
    int limit = 200,
    String? parentId,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
  });

  Future<List<LibraryItem>> fetchRecentlyPlayed(AuthSession session);

  Future<List<LibraryItem>> fetchFavorites(AuthSession session);

  Future<List<LyricsLine>> fetchLyrics(
    AuthSession session,
    String itemId,
  );

  Future<void> setFavorite(
    AuthSession session,
    String itemId,
    bool favorite,
  );

  Uri imageUri(AuthSession session, String itemId, {int width = 600});

  Uri streamUri(
    AuthSession session,
    LibraryItem item, {
    int? maxBitrate,
  });

  Map<String, String> playbackHeaders(AuthSession session);

  Future<void> reportPlaybackStarted(
    AuthSession session,
    LibraryItem item,
  );

  Future<void> reportPlaybackProgress(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    required bool paused,
  });

  Future<void> reportPlaybackStopped(
    AuthSession session,
    LibraryItem item,
    Duration position,
  );
}

abstract interface class CredentialStore {
  Future<void> writeToken(String profileId, String token);

  Future<String?> readToken(String profileId);

  Future<void> deleteToken(String profileId);
}

abstract interface class LibraryRepository {
  Future<List<LibraryItem>> readCachedLibrary(String serverId);

  Future<void> cacheLibrary(String serverId, List<LibraryItem> items);

  Future<List<LibraryItem>> synchronize(AuthSession session);

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

  Future<void> setShuffle(bool enabled);

  Future<void> setRepeat(RepeatMode mode);

  Future<void> setVolume(double volume);

  Future<void> stop();
}

abstract interface class PlaybackCoordinator implements PlaybackEngine {
  PlaybackSnapshot get currentSnapshot;
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

  Future<void> reconcile();
}

abstract interface class PlatformMediaBridge {
  PlatformCapabilities get capabilities;

  Future<void> showOutputPicker();

  Future<void> connectCastDevice(String deviceId);

  Future<void> applyEqualizer(List<double> bands);
}
