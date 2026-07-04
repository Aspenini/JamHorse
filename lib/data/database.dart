import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// Drift table declarations are compile-time DSL consumed by generated code.
// coverage:ignore-start
class ServerProfiles extends Table {
  TextColumn get profileId => text()();
  TextColumn get serverId => text()();
  TextColumn get baseUrl => text()();
  TextColumn get name => text()();
  TextColumn get userId => text()();
  TextColumn get username => text()();
  TextColumn get deviceId => text()();
  TextColumn get serverVersion => text()();
  BoolColumn get allowPrivateHttp =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {profileId};
}

class CachedItems extends Table {
  TextColumn get profileId => text()();
  TextColumn get serverId => text()();
  TextColumn get itemId => text()();
  TextColumn get itemType => text()();
  TextColumn get name => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get albumId => text().nullable()();
  TextColumn get albumName => text().nullable()();
  TextColumn get artistId => text().nullable()();
  TextColumn get artistsJson => text().withDefault(const Constant('[]'))();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get indexNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get productionYear => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get hasPrimaryImage =>
      boolean().withDefault(const Constant(false))();
  TextColumn get container => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {profileId, itemId};
}

class DownloadEntries extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get itemId => text()();
  TextColumn get status => text()();
  TextColumn get filePath => text().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get checksum => text().nullable()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class QueueEntries extends Table {
  TextColumn get profileId => text()();
  IntColumn get queueIndex => integer()();
  TextColumn get itemId => text()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {profileId, queueIndex};
}

class PlaybackStates extends Table {
  TextColumn get profileId => text()();
  IntColumn get currentIndex => integer().withDefault(const Constant(-1))();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  BoolColumn get shuffle => boolean().withDefault(const Constant(false))();
  TextColumn get repeatMode => text().withDefault(const Constant('off'))();
  DateTimeColumn get sleepDeadline => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {profileId};
}

class PendingReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get profileId => text()();
  TextColumn get itemId => text()();
  TextColumn get playSessionId => text()();
  TextColumn get eventType => text()();
  IntColumn get positionMs => integer()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
}
// coverage:ignore-end

@DriftDatabase(
  tables: [
    ServerProfiles,
    CachedItems,
    DownloadEntries,
    QueueEntries,
    PlaybackStates,
    PendingReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'jamhorse'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      // JamHorse has not shipped a stable release. Version 2 intentionally
      // resets the pre-release schema so account-scoped identifiers cannot be
      // confused with remote Jellyfin server ids.
      if (from < 2) {
        for (final table in [
          'pending_reports',
          'queue_entries',
          'download_entries',
          'cached_items',
          'server_profiles',
        ]) {
          await customStatement('DROP TABLE IF EXISTS $table');
        }
        await migrator.createAll();
      }
    },
  );

  Future<List<ServerProfile>> allProfiles() {
    return (select(
      serverProfiles,
    )..orderBy([(row) => OrderingTerm.desc(row.lastUsedAt)])).get();
  }

  Future<void> saveProfile(ServerProfilesCompanion profile) {
    return into(serverProfiles).insertOnConflictUpdate(profile);
  }

  Future<void> removeProfile(String id) async {
    await transaction(() async {
      await (delete(
        serverProfiles,
      )..where((row) => row.profileId.equals(id))).go();
      await (delete(
        cachedItems,
      )..where((row) => row.profileId.equals(id))).go();
      await (delete(
        queueEntries,
      )..where((row) => row.profileId.equals(id))).go();
      await (delete(
        playbackStates,
      )..where((row) => row.profileId.equals(id))).go();
      await (delete(
        downloadEntries,
      )..where((row) => row.profileId.equals(id))).go();
      await (delete(
        pendingReports,
      )..where((row) => row.profileId.equals(id))).go();
    });
  }

  Future<List<CachedItem>> libraryFor(String profileId) {
    return (select(cachedItems)
          ..where((row) => row.profileId.equals(profileId))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
  }

  Future<void> replaceLibrary(
    String profileId,
    List<CachedItemsCompanion> items,
  ) {
    return transaction(() async {
      await (delete(
        cachedItems,
      )..where((row) => row.profileId.equals(profileId))).go();
      await batch((batch) => batch.insertAll(cachedItems, items));
    });
  }

  Future<List<DownloadEntry>> allDownloads() {
    return (select(
      downloadEntries,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();
  }

  Future<void> upsertDownload(DownloadEntriesCompanion entry) {
    return into(downloadEntries).insertOnConflictUpdate(entry);
  }

  Future<void> deleteDownload(String id) {
    return (delete(downloadEntries)..where((row) => row.id.equals(id))).go();
  }

  Future<List<DownloadEntry>> completedDownloadsOldestFirst() {
    return (select(downloadEntries)
          ..where((row) => row.status.equals('complete'))
          ..orderBy([
            (row) => OrderingTerm.asc(row.lastPlayedAt),
            (row) => OrderingTerm.asc(row.updatedAt),
          ]))
        .get();
  }

  Future<String?> completedDownloadPath(String profileId, String itemId) async {
    final row =
        await (select(downloadEntries)
              ..where(
                (row) =>
                    row.profileId.equals(profileId) &
                    row.itemId.equals(itemId) &
                    row.status.equals('complete'),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.filePath;
  }

  Future<void> insertPendingReport(PendingReportsCompanion report) async {
    if (report.eventType.value == 'progress') {
      await (delete(pendingReports)..where(
            (row) =>
                row.profileId.equals(report.profileId.value) &
                row.itemId.equals(report.itemId.value) &
                row.playSessionId.equals(report.playSessionId.value) &
                row.eventType.equals('progress'),
          ))
          .go();
    }
    await into(pendingReports).insert(report);
    // Cap the queue so an extended offline stretch cannot grow it forever.
    final ids =
        await (selectOnly(pendingReports)
              ..addColumns([pendingReports.id])
              ..orderBy([OrderingTerm.desc(pendingReports.id)])
              ..limit(1, offset: 200))
            .map((row) => row.read(pendingReports.id)!)
            .get();
    if (ids.isNotEmpty) {
      await (delete(
        pendingReports,
      )..where((row) => row.id.isSmallerOrEqualValue(ids.first))).go();
    }
  }

  Future<List<PendingReport>> oldestPendingReports(
    String profileId, {
    int limit = 50,
  }) {
    return (select(pendingReports)
          ..where((row) => row.profileId.equals(profileId))
          ..orderBy([(row) => OrderingTerm.asc(row.id)])
          ..limit(limit))
        .get();
  }

  Future<void> deletePendingReport(int id) {
    return (delete(pendingReports)..where((row) => row.id.equals(id))).go();
  }

  Future<void> replaceQueue(
    String profileId,
    List<QueueEntriesCompanion> entries,
    PlaybackStatesCompanion playback,
  ) {
    return transaction(() async {
      await (delete(
        queueEntries,
      )..where((row) => row.profileId.equals(profileId))).go();
      if (entries.isNotEmpty) {
        await batch((batch) => batch.insertAll(queueEntries, entries));
      }
      await into(playbackStates).insertOnConflictUpdate(playback);
    });
  }

  Future<List<QueueEntry>> queueFor(String profileId) {
    return (select(queueEntries)
          ..where((row) => row.profileId.equals(profileId))
          ..orderBy([(row) => OrderingTerm.asc(row.queueIndex)]))
        .get();
  }

  Future<PlaybackState?> playbackStateFor(String profileId) {
    return (select(
      playbackStates,
    )..where((row) => row.profileId.equals(profileId))).getSingleOrNull();
  }

  Future<void> markDownloadPlayed(String profileId, String itemId) {
    return (update(downloadEntries)..where(
          (row) =>
              row.profileId.equals(profileId) &
              row.itemId.equals(itemId) &
              row.status.equals('complete'),
        ))
        .write(DownloadEntriesCompanion(lastPlayedAt: Value(DateTime.now())));
  }
}
