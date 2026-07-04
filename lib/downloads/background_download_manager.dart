import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bg;
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/data/database.dart' as db;
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class JamHorseDownloadManager implements DownloadManager {
  JamHorseDownloadManager(this._gateway, this._database) {
    _ready = _initialize();
  }

  final JellyfinGateway _gateway;
  final db.AppDatabase _database;
  final bg.FileDownloader _downloader = bg.FileDownloader();
  final _controller = StreamController<List<DownloadRecord>>.broadcast();
  final _records = <String, DownloadRecord>{};
  final _tasks = <String, bg.DownloadTask>{};
  late final StreamSubscription<bg.TaskUpdate> _updates;
  late final Future<void> _ready;
  Future<void> _updateSerial = Future.value();
  final _lastProgressPersist = <String, DateTime>{};

  @override
  Stream<List<DownloadRecord>> get records {
    // Late subscribers get the current state immediately.
    _ready.then((_) => _emit());
    return _controller.stream;
  }

  /// Initializes the native downloader before subscribing, then reconciles
  /// native tasks, database rows, and files.
  Future<void> _initialize() async {
    await _downloader.start();
    _updates = _downloader.updates.listen((update) {
      _updateSerial = _updateSerial
          .catchError((Object error, StackTrace stack) {
            appLog.warning('Download update failed', error, stack);
          })
          .then((_) => _handleUpdate(update));
    });
    final rows = await _database.allDownloads();
    for (final row in rows) {
      final status = DownloadStatus.values.firstWhere(
        (value) => value.name == row.status,
        orElse: () => DownloadStatus.failed,
      );
      if (status == DownloadStatus.complete &&
          (row.filePath == null || !File(row.filePath!).existsSync())) {
        // The file is gone (evicted or removed externally); drop the row.
        await _database.deleteDownload(row.id);
        continue;
      }
      _records[row.id] = DownloadRecord(
        id: row.id,
        profileId: row.profileId,
        itemId: row.itemId,
        status: status,
        filePath: row.filePath,
        progress: status == DownloadStatus.complete ? 1 : row.progress,
        sizeBytes: row.sizeBytes,
        checksum: row.checksum,
        lastPlayedAt: row.lastPlayedAt,
      );
    }
    final tasks = await _downloader.allTasks(allGroups: true);
    for (final task in tasks.whereType<bg.DownloadTask>()) {
      if (_records.containsKey(task.taskId)) {
        _tasks[task.taskId] = task;
      } else {
        // A native task without a database owner can leak credentials and
        // partial files, so cancel and remove it during startup reconciliation.
        await _downloader.cancelTaskWithId(task.taskId);
        final path = await task.filePath();
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    for (final entry in _records.entries.toList()) {
      final record = entry.value;
      if ((record.status == DownloadStatus.downloading ||
              record.status == DownloadStatus.queued) &&
          !_tasks.containsKey(record.id)) {
        _records[record.id] = record.copyWith(status: DownloadStatus.paused);
        await _persist(_records[record.id]!);
      }
    }
    _emit();
  }

  @override
  Future<void> enqueue(
    AuthSession session,
    LibraryItem item, {
    bool wifiOnly = false,
  }) async {
    await _ready;
    // One completed copy per track is enough.
    final existing = _records.values.firstWhereOrNull(
      (record) =>
          record.itemId == item.id &&
          record.profileId == session.profile.profileId &&
          record.status != DownloadStatus.failed,
    );
    if (existing != null) return;
    final id = const Uuid().v4();
    final extension = _safeExtension(item.container);
    final task = bg.DownloadTask(
      taskId: id,
      url: _gateway.streamUri(session, item).toString(),
      headers: _gateway.playbackHeaders(session),
      filename: '${item.id}.$extension',
      directory: 'downloads/${session.profile.profileId}',
      baseDirectory: bg.BaseDirectory.applicationSupport,
      group: session.profile.profileId,
      updates: bg.Updates.statusAndProgress,
      requiresWiFi: wifiOnly,
      retries: 3,
      allowPause: true,
      displayName: item.name,
      metaData: '${session.profile.profileId}|${item.id}',
    );
    _tasks[id] = task;
    _records[id] = DownloadRecord(
      id: id,
      profileId: session.profile.profileId,
      itemId: item.id,
      status: DownloadStatus.queued,
    );
    await _persist(_records[id]!);
    _emit();
    final accepted = await _downloader.enqueue(task);
    if (!accepted) {
      _records[id] = _records[id]!.copyWith(status: DownloadStatus.failed);
      await _persist(_records[id]!);
      _emit();
    }
  }

  @override
  Future<void> pause(String downloadId) async {
    final persisted = await _downloader.taskForId(downloadId);
    final task =
        _tasks[downloadId] ?? (persisted is bg.DownloadTask ? persisted : null);
    if (task == null) return;
    _tasks[downloadId] = task;
    await _downloader.pause(task);
  }

  @override
  Future<void> resume(String downloadId) async {
    final persisted = await _downloader.taskForId(downloadId);
    final task =
        _tasks[downloadId] ?? (persisted is bg.DownloadTask ? persisted : null);
    if (task != null) {
      _tasks[downloadId] = task;
      await _downloader.resume(task);
      return;
    }
    // Restored from a previous session: the platform task is gone, so mark
    // it failed and let the user re-download from the library.
    final record = _records[downloadId];
    if (record != null && record.status != DownloadStatus.complete) {
      _records[downloadId] = record.copyWith(status: DownloadStatus.failed);
      await _persist(_records[downloadId]!);
      _emit();
    }
  }

  @override
  Future<void> cancel(String downloadId) async {
    await delete(downloadId);
  }

  @override
  Future<void> delete(String downloadId) async {
    final record = _records.remove(downloadId);
    final task = _tasks.remove(downloadId);
    await _downloader.cancelTaskWithId(downloadId);
    final path = record?.filePath ?? (await task?.filePath());
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await _database.deleteDownload(downloadId);
    _emit();
  }

  @override
  Future<void> reconcile() async {
    await _ready;
    await _downloader.resumeFromBackground();
    _emit();
  }

  @override
  Future<void> retry(
    String downloadId,
    AuthSession session,
    LibraryItem item,
  ) async {
    await delete(downloadId);
    await enqueue(session, item);
  }

  @override
  Future<void> purgeProfile(String profileId) async {
    await _ready;
    await _downloader.cancelAll(group: profileId);
    final ids = _records.values
        .where((record) => record.profileId == profileId)
        .map((record) => record.id)
        .toList(growable: false);
    for (final id in ids) {
      await delete(id);
    }
  }

  @override
  Future<void> markPlayed(String profileId, String itemId) async {
    await _database.markDownloadPlayed(profileId, itemId);
    final match = _records.values.firstWhereOrNull(
      (record) =>
          record.profileId == profileId &&
          record.itemId == itemId &&
          record.status == DownloadStatus.complete,
    );
    if (match != null) {
      _records[match.id] = match.copyWith(lastPlayedAt: DateTime.now());
      _emit();
    }
  }

  Future<void> _handleUpdate(bg.TaskUpdate update) async {
    final record = _records[update.task.taskId];
    if (record == null) return;
    if (update case bg.TaskProgressUpdate()) {
      _records[record.id] = record.copyWith(
        progress: update.progress.clamp(0, 1),
        sizeBytes: update.hasExpectedFileSize ? update.expectedFileSize : null,
      );
      final now = DateTime.now();
      final last = _lastProgressPersist[record.id];
      if (last == null || now.difference(last) >= const Duration(seconds: 1)) {
        _lastProgressPersist[record.id] = now;
        await _persist(_records[record.id]!);
      }
    } else if (update case bg.TaskStatusUpdate()) {
      final status = switch (update.status) {
        bg.TaskStatus.enqueued ||
        bg.TaskStatus.waitingToRetry => DownloadStatus.queued,
        bg.TaskStatus.running => DownloadStatus.downloading,
        bg.TaskStatus.paused => DownloadStatus.paused,
        bg.TaskStatus.complete => DownloadStatus.complete,
        bg.TaskStatus.notFound ||
        bg.TaskStatus.failed ||
        bg.TaskStatus.canceled => DownloadStatus.failed,
      };
      var filePath = record.filePath;
      var sizeBytes = record.sizeBytes;
      if (status == DownloadStatus.complete) {
        filePath = await update.task.filePath();
        final file = File(filePath);
        if (await file.exists()) sizeBytes = await file.length();
      }
      _records[record.id] = record.copyWith(
        status: status,
        filePath: filePath,
        sizeBytes: sizeBytes,
        progress: status == DownloadStatus.complete ? 1 : null,
      );
      await _persist(_records[record.id]!);
      if (status == DownloadStatus.complete) {
        await enforceStorageLimit();
      }
    }
    _emit();
  }

  /// Deletes the oldest completed downloads until total size fits the
  /// configured limit. 0 means unlimited.
  @override
  Future<void> enforceStorageLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final limitGb = prefs.getInt('downloadStorageLimitGb') ?? 10;
    if (limitGb <= 0) return;
    final limitBytes = limitGb * 1024 * 1024 * 1024;
    final completed = await _database.completedDownloadsOldestFirst();
    var total = 0;
    final sizes = <String, int>{};
    for (final row in completed) {
      var size = row.sizeBytes;
      if (size <= 0 && row.filePath != null) {
        final file = File(row.filePath!);
        size = await file.exists() ? await file.length() : 0;
      }
      sizes[row.id] = size;
      total += size;
    }
    for (final row in completed) {
      if (total <= limitBytes) break;
      appLog.info('Storage limit: evicting download ${row.itemId}');
      await delete(row.id);
      total -= sizes[row.id] ?? 0;
    }
  }

  Future<void> _persist(DownloadRecord record) {
    return _database.upsertDownload(
      db.DownloadEntriesCompanion.insert(
        id: record.id,
        profileId: record.profileId,
        itemId: record.itemId,
        status: record.status.name,
        filePath: Value(record.filePath),
        progress: Value(record.progress),
        sizeBytes: Value(record.sizeBytes),
        checksum: Value(record.checksum),
        lastPlayedAt: Value(record.lastPlayedAt),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(List.unmodifiable(_records.values));
  }

  Future<void> dispose() async {
    await _ready;
    await _updateSerial;
    await _updates.cancel();
    await _controller.close();
  }
}

String _safeExtension(String? container) {
  final candidate = (container?.split(',').firstOrNull ?? 'm4a')
      .toLowerCase()
      .trim();
  return RegExp(r'^[a-z0-9]{1,8}$').hasMatch(candidate) ? candidate : 'm4a';
}

extension on DownloadRecord {
  DownloadRecord copyWith({
    DownloadStatus? status,
    String? filePath,
    double? progress,
    int? sizeBytes,
    DateTime? lastPlayedAt,
  }) {
    return DownloadRecord(
      id: id,
      profileId: profileId,
      itemId: itemId,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}
