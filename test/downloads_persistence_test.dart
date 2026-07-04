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
        profileId: 'profile-a',
        itemId: 'track-1',
        status: 'complete',
        filePath: const Value('/tmp/track-1.flac'),
        sizeBytes: const Value(1000),
        updatedAt: DateTime(2026),
      ),
    );

    expect((await database.allDownloads()).single.itemId, 'track-1');
    expect(
      await database.completedDownloadPath('profile-a', 'track-1'),
      '/tmp/track-1.flac',
    );
    expect(await database.completedDownloadPath('profile-a', 'other'), isNull);

    await database.deleteDownload('dl-1');
    expect(await database.allDownloads(), isEmpty);
  });

  test('completed downloads list oldest first for eviction', () async {
    for (final (id, year) in [('new', 2026), ('old', 2024), ('mid', 2025)]) {
      await database.upsertDownload(
        DownloadEntriesCompanion.insert(
          id: id,
          profileId: 'p',
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
          profileId: 'p',
          itemId: 'item-$i',
          playSessionId: 'play-$i',
          eventType: 'progress',
          positionMs: i,
          payloadJson: '{"paused":false}',
          createdAt: DateTime(2026),
        ),
      );
    }
    final pending = await database.oldestPendingReports('p', limit: 500);
    expect(pending.length, 200);
    // The oldest rows were trimmed, newest kept.
    expect(pending.last.itemId, 'item-229');
  });

  test('obsolete progress reports are coalesced per play session', () async {
    for (final position in [100, 200, 300]) {
      await database.insertPendingReport(
        PendingReportsCompanion.insert(
          profileId: 'p',
          itemId: 'track',
          playSessionId: 'play',
          eventType: 'progress',
          positionMs: position,
          payloadJson: '{"paused":false}',
          createdAt: DateTime(2026),
        ),
      );
    }

    final pending = await database.oldestPendingReports('p');
    expect(pending, hasLength(1));
    expect(pending.single.positionMs, 300);
  });

  test(
    'recently played downloads move behind unplayed content for eviction',
    () async {
      for (final id in ['played', 'unplayed']) {
        await database.upsertDownload(
          DownloadEntriesCompanion.insert(
            id: id,
            profileId: 'p',
            itemId: id,
            status: 'complete',
            updatedAt: DateTime(2026),
          ),
        );
      }

      await database.markDownloadPlayed('p', 'played');

      final ordered = await database.completedDownloadsOldestFirst();
      expect(ordered.map((row) => row.id), ['unplayed', 'played']);
    },
  );
}
