import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class ServerProfiles extends Table {
  TextColumn get id => text()();
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
  Set<Column<Object>> get primaryKey => {id};
}

class CachedItems extends Table {
  TextColumn get serverId => text()();
  TextColumn get itemId => text()();
  TextColumn get itemType => text()();
  TextColumn get name => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get albumId => text().nullable()();
  TextColumn get artistId => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get indexNumber => integer().nullable()();
  IntColumn get productionYear => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isDownloaded =>
      boolean().withDefault(const Constant(false))();
  TextColumn get container => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {serverId, itemId};
}

class DownloadEntries extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text()();
  TextColumn get itemId => text()();
  TextColumn get status => text()();
  TextColumn get filePath => text().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get checksum => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class QueueEntries extends Table {
  TextColumn get serverId => text()();
  IntColumn get queueIndex => integer()();
  TextColumn get itemId => text()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {serverId, queueIndex};
}

class PendingReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  TextColumn get itemId => text()();
  TextColumn get eventType => text()();
  IntColumn get positionMs => integer()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    ServerProfiles,
    CachedItems,
    DownloadEntries,
    QueueEntries,
    PendingReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'jamhorse'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<ServerProfile>> allProfiles() {
    return (select(
      serverProfiles,
    )..orderBy([(row) => OrderingTerm.desc(row.lastUsedAt)])).get();
  }

  Future<void> saveProfile(ServerProfilesCompanion profile) {
    return into(serverProfiles).insertOnConflictUpdate(profile);
  }

  Future<void> removeProfile(String id) async {
    await (delete(serverProfiles)..where((row) => row.id.equals(id))).go();
    await (delete(cachedItems)..where((row) => row.serverId.equals(id))).go();
    await (delete(queueEntries)..where((row) => row.serverId.equals(id))).go();
    await (delete(
      downloadEntries,
    )..where((row) => row.serverId.equals(id))).go();
    await (delete(pendingReports)..where((row) => row.serverId.equals(id))).go();
  }

  Future<List<CachedItem>> libraryFor(String serverId) {
    return (select(cachedItems)
          ..where((row) => row.serverId.equals(serverId))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .get();
  }

  Future<void> replaceLibrary(
    String serverId,
    List<CachedItemsCompanion> items,
  ) {
    return transaction(() async {
      await (delete(
        cachedItems,
      )..where((row) => row.serverId.equals(serverId))).go();
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
    return (delete(
      downloadEntries,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<List<DownloadEntry>> completedDownloadsOldestFirst() {
    return (select(downloadEntries)
          ..where((row) => row.status.equals('complete'))
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<String?> completedDownloadPath(String serverId, String itemId) async {
    final row =
        await (select(downloadEntries)
              ..where(
                (row) =>
                    row.serverId.equals(serverId) &
                    row.itemId.equals(itemId) &
                    row.status.equals('complete'),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.filePath;
  }

  Future<void> insertPendingReport(PendingReportsCompanion report) async {
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
    String serverId, {
    int limit = 50,
  }) {
    return (select(pendingReports)
          ..where((row) => row.serverId.equals(serverId))
          ..orderBy([(row) => OrderingTerm.asc(row.id)])
          ..limit(limit))
        .get();
  }

  Future<void> deletePendingReport(int id) {
    return (delete(pendingReports)..where((row) => row.id.equals(id))).go();
  }
}
