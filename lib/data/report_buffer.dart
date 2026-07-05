import 'dart:convert';

import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/data/database.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';

/// Wraps a [JellyfinGateway] so playback reports survive being offline:
/// failed reports are queued in the database and flushed, oldest first,
/// the next time a report goes through.
class ReportBufferingGateway implements JellyfinGateway {
  ReportBufferingGateway(this._inner, this._database);

  final JellyfinGateway _inner;
  final AppDatabase _database;
  Future<void> _serial = Future.value();

  @override
  Future<void> reportPlaybackStarted(
    AuthSession session,
    LibraryItem item, {
    String? playSessionId,
  }) {
    return _sendOrQueue(
      session,
      item,
      'started',
      Duration.zero,
      false,
      playSessionId,
    );
  }

  @override
  Future<void> reportPlaybackProgress(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    required bool paused,
    String? playSessionId,
  }) {
    return _sendOrQueue(
      session,
      item,
      'progress',
      position,
      paused,
      playSessionId,
    );
  }

  @override
  Future<void> reportPlaybackStopped(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    String? playSessionId,
  }) {
    return _sendOrQueue(
      session,
      item,
      'stopped',
      position,
      true,
      playSessionId,
    );
  }

  Future<void> _sendOrQueue(
    AuthSession session,
    LibraryItem item,
    String eventType,
    Duration position,
    bool paused,
    String? playSessionId,
  ) {
    final operation = _serial.then(
      (_) => _sendOrQueueSerial(
        session,
        item,
        eventType,
        position,
        paused,
        playSessionId ?? '${session.profile.deviceId}-${item.id}',
      ),
    );
    _serial = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _sendOrQueueSerial(
    AuthSession session,
    LibraryItem item,
    String eventType,
    Duration position,
    bool paused,
    String playSessionId,
  ) async {
    try {
      await _flush(session);
      await _send(session, item.id, eventType, position, paused, playSessionId);
    } catch (error) {
      try {
        await _database.insertPendingReport(
          PendingReportsCompanion.insert(
            profileId: session.profile.profileId,
            itemId: item.id,
            playSessionId: playSessionId,
            eventType: eventType,
            positionMs: position.inMilliseconds,
            payloadJson: jsonEncode({'paused': paused}),
            createdAt: DateTime.now(),
          ),
        );
        appLog.fine('Playback report queued for retry: $eventType');
      } catch (persistenceError) {
        appLog.warning(
          'Playback report could not be queued: $persistenceError',
        );
      }
    }
  }

  Future<void> _flush(AuthSession session) async {
    final pending = await _database.oldestPendingReports(
      session.profile.profileId,
    );
    if (pending.isEmpty) return;
    for (final report in pending) {
      var paused = true;
      try {
        paused =
            (jsonDecode(report.payloadJson) as Map<String, dynamic>)['paused']
                as bool? ??
            true;
      } catch (_) {
        // Old/corrupt metadata must not permanently poison the ordered queue.
      }
      await _send(
        session,
        report.itemId,
        report.eventType,
        Duration(milliseconds: report.positionMs),
        paused,
        report.playSessionId,
      );
      await _database.deletePendingReport(report.id);
    }
    appLog.info('Flushed ${pending.length} buffered playback reports');
  }

  Future<void> _send(
    AuthSession session,
    String itemId,
    String eventType,
    Duration position,
    bool paused,
    String playSessionId,
  ) {
    // The reporting endpoints only use the item id.
    final item = LibraryItem(
      id: itemId,
      profileId: session.profile.profileId,
      serverId: session.profile.serverId,
      type: LibraryItemType.track,
      name: '',
    );
    return switch (eventType) {
      'started' => _inner.reportPlaybackStarted(
        session,
        item,
        playSessionId: playSessionId,
      ),
      'stopped' => _inner.reportPlaybackStopped(
        session,
        item,
        position,
        playSessionId: playSessionId,
      ),
      _ => _inner.reportPlaybackProgress(
        session,
        item,
        position,
        paused: paused,
        playSessionId: playSessionId,
      ),
    };
  }

  // Everything else passes straight through.

  @override
  Future<AuthSession> authenticate({
    required Uri baseUrl,
    required String username,
    required String password,
    required String deviceId,
    required bool allowPrivateHttp,
  }) {
    return _inner.authenticate(
      baseUrl: baseUrl,
      username: username,
      password: password,
      deviceId: deviceId,
      allowPrivateHttp: allowPrivateHttp,
    );
  }

  @override
  Future<ServerInfo> inspectServer(Uri baseUrl) =>
      _inner.inspectServer(baseUrl);

  @override
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
  }) {
    return _inner.fetchLibraryPage(
      session,
      types: types,
      limit: limit,
      parentId: parentId,
      searchTerm: searchTerm,
      sortBy: sortBy,
      sortOrder: sortOrder,
      startIndex: startIndex,
      context: context,
    );
  }

  @override
  Future<List<LibraryItem>> fetchFavorites(AuthSession session) =>
      _inner.fetchFavorites(session);

  @override
  Future<List<LibraryItem>> fetchRecentlyPlayed(AuthSession session) =>
      _inner.fetchRecentlyPlayed(session);

  @override
  Future<List<LyricsLine>> fetchLyrics(AuthSession session, String itemId) =>
      _inner.fetchLyrics(session, itemId);

  @override
  Future<void> setFavorite(AuthSession session, String itemId, bool favorite) =>
      _inner.setFavorite(session, itemId, favorite);

  @override
  Uri imageUri(AuthSession session, String itemId, {int width = 600}) =>
      _inner.imageUri(session, itemId, width: width);

  @override
  Uri userImageUri(AuthSession session, {int width = 128}) =>
      _inner.userImageUri(session, width: width);

  @override
  Uri streamUri(AuthSession session, LibraryItem item, {int? maxBitrate}) =>
      _inner.streamUri(session, item, maxBitrate: maxBitrate);

  @override
  Map<String, String> playbackHeaders(AuthSession session) =>
      _inner.playbackHeaders(session);
}
