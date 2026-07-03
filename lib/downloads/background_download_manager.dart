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
    _updates = bg.FileDownloader().updates.listen(_handleUpdate);
    _ready = _restore();
  }

  final JellyfinGateway _gateway;
  final db.AppDatabase _database;
  final _controller = StreamController<List<DownloadRecord>>.broadcast();
  final _records = <String, DownloadRecord>{};
  final _tasks = <String, bg.DownloadTask>{};
  late final StreamSubscription<bg.TaskUpdate> _updates;
  late final Future<void> _ready;

  @override
  Stream<List<DownloadRecord>> get records {
    // Late subscribers get the current state immediately.
    _ready.then((_) => _emit());
    return _controller.stream;
  }

  /// Loads persisted records so the Downloads screen survives restarts.
  Future<void> _restore() async {
    final rows = await _database.allDownloads();
    for (final row in rows) {
      var status = DownloadStatus.values.firstWhere(
        (value) => value.name == row.status,
        orElse: () => DownloadStatus.failed,
      );
      // Anything that was mid-flight when the app quit is either picked up
      // again by resumeFromBackground or needs a fresh enqueue.
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.queued) {
        status = DownloadStatus.paused;
      }
      if (status == DownloadStatus.complete &&
          (row.filePath == null || !File(row.filePath!).existsSync())) {
        // The file is gone (evicted or removed externally); drop the row.
        await _database.deleteDownload(row.id);
        continue;
      }
      _records[row.id] = DownloadRecord(
        id: row.id,
        serverId: row.serverId,
        itemId: row.itemId,
        status: status,
        filePath: row.filePath,
        progress: status == DownloadStatus.complete ? 1 : row.progress,
        sizeBytes: row.sizeBytes,
        checksum: row.checksum,
      );
    }
    await bg.FileDownloader().resumeFromBackground();
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
          record.serverId == session.profile.id &&
          record.status != DownloadStatus.failed,
    );
    if (existing != null) return;
    final id = const Uuid().v4();
    final extension =
        (item.container?.split(',').firstOrNull ?? 'm4a').toLowerCase();
    final task = bg.DownloadTask(
      taskId: id,
      url: _gateway.streamUri(session, item).toString(),
      headers: _gateway.playbackHeaders(session),
      filename: '${item.id}.$extension',
      directory: 'downloads/${session.profile.id}',
      baseDirectory: bg.BaseDirectory.applicationSupport,
      group: session.profile.id,
      updates: bg.Updates.statusAndProgress,
      requiresWiFi: wifiOnly,
      retries: 3,
      allowPause: true,
      displayName: item.name,
      metaData: '${session.profile.id}|${item.id}',
    );
    _tasks[id] = task;
    _records[id] = DownloadRecord(
      id: id,
      serverId: session.profile.id,
      itemId: item.id,
      status: DownloadStatus.queued,
    );
    await _persist(_records[id]!);
    _emit();
    final accepted = await bg.FileDownloader().enqueue(task);
    if (!accepted) {
      _records[id] = _records[id]!.copyWith(status: DownloadStatus.failed);
      await _persist(_records[id]!);
      _emit();
    }
  }

  @override
  Future<void> pause(String downloadId) async {
    final task = _tasks[downloadId];
    if (task == null) return;
    await bg.FileDownloader().pause(task);
  }

  @override
  Future<void> resume(String downloadId) async {
    final task = _tasks[downloadId];
    if (task != null) {
      await bg.FileDownloader().resume(task);
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
    final task = _tasks.remove(downloadId);
    if (task != null) await bg.FileDownloader().cancel(task);
    _records.remove(downloadId);
    await _database.deleteDownload(downloadId);
    _emit();
  }

  @override
  Future<void> delete(String downloadId) async {
    final record = _records.remove(downloadId);
    final task = _tasks.remove(downloadId);
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
    await bg.FileDownloader().resumeFromBackground();
    _emit();
  }

  Future<void> _handleUpdate(bg.TaskUpdate update) async {
    final record = _records[update.task.taskId];
    if (record == null) return;
    if (update case bg.TaskProgressUpdate()) {
      _records[record.id] = record.copyWith(
        progress: update.progress.clamp(0, 1),
        sizeBytes: update.hasExpectedFileSize ? update.expectedFileSize : null,
      );
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
        await _enforceStorageLimit();
      }
    }
    _emit();
  }

  /// Deletes the oldest completed downloads until total size fits the
  /// configured limit. 0 means unlimited.
  Future<void> _enforceStorageLimit() async {
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
        serverId: record.serverId,
        itemId: record.itemId,
        status: record.status.name,
        filePath: Value(record.filePath),
        progress: Value(record.progress),
        sizeBytes: Value(record.sizeBytes),
        checksum: Value(record.checksum),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(List.unmodifiable(_records.values));
  }

  Future<void> dispose() async {
    await _updates.cancel();
    await _controller.close();
  }
}

extension on DownloadRecord {
  DownloadRecord copyWith({
    DownloadStatus? status,
    String? filePath,
    double? progress,
    int? sizeBytes,
  }) {
    return DownloadRecord(
      id: id,
      serverId: serverId,
      itemId: itemId,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      checksum: checksum,
    );
  }
}
