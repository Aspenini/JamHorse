import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/data/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('download records persist and resolve local paths', () async {
    await database.upsertDownload(
      DownloadEntriesCompanion.insert(
        id: 'dl-1',
        serverId: 'server-a',
        itemId: 'track-1',
        status: 'complete',
        filePath: const Value('/tmp/track-1.flac'),
        sizeBytes: const Value(1000),
        updatedAt: DateTime(2026),
      ),
    );

    expect((await database.allDownloads()).single.itemId, 'track-1');
    expect(
      await database.completedDownloadPath('server-a', 'track-1'),
      '/tmp/track-1.flac',
    );
    expect(await database.completedDownloadPath('server-a', 'other'), isNull);

    await database.deleteDownload('dl-1');
    expect(await database.allDownloads(), isEmpty);
  });

  test('completed downloads list oldest first for eviction', () async {
    for (final (id, year) in [('new', 2026), ('old', 2024), ('mid', 2025)]) {
      await database.upsertDownload(
        DownloadEntriesCompanion.insert(
          id: id,
          serverId: 's',
          itemId: id,
          status: 'complete',
          updatedAt: DateTime(year),
        ),
      );
    }
    final ordered = await database.completedDownloadsOldestFirst();
    expect(ordered.map((row) => row.id).toList(), ['old', 'mid', 'new']);
  });

  test('pending report queue is capped at 200', () async {
    for (var i = 0; i < 230; i++) {
      await database.insertPendingReport(
        PendingReportsCompanion.insert(
          serverId: 's',
          itemId: 'item-$i',
          eventType: 'progress',
          positionMs: i,
          payloadJson: '{"paused":false}',
          createdAt: DateTime(2026),
        ),
      );
    }
    final pending = await database.oldestPendingReports('s', limit: 500);
    expect(pending.length, 200);
    // The oldest rows were trimmed, newest kept.
    expect(pending.last.itemId, 'item-229');
  });
}
