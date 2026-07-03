import 'package:drift/drift.dart';
import 'package:jamhorse/data/database.dart' as db;
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';

class ProfileRepository {
  const ProfileRepository(this._database, this._credentials);

  final db.AppDatabase _database;
  final CredentialStore _credentials;

  Future<List<ServerProfile>> all() async {
    final rows = await _database.allProfiles();
    return rows.map(_mapProfile).toList(growable: false);
  }

  Future<void> save(AuthSession session) async {
    final profile = session.profile;
    await _database.saveProfile(
      db.ServerProfilesCompanion.insert(
        id: profile.id,
        baseUrl: profile.baseUrl.toString(),
        name: profile.name,
        userId: profile.userId,
        username: profile.username,
        deviceId: profile.deviceId,
        serverVersion: profile.serverVersion,
        allowPrivateHttp: Value(profile.allowPrivateHttp),
        lastUsedAt: DateTime.now(),
      ),
    );
    await _credentials.writeToken(profile.id, session.token);
  }

  Future<AuthSession?> restore(ServerProfile profile) async {
    final token = await _credentials.readToken(profile.id);
    return token == null ? null : AuthSession(profile: profile, token: token);
  }

  Future<void> remove(String profileId) async {
    await _credentials.deleteToken(profileId);
    await _database.removeProfile(profileId);
  }

  ServerProfile _mapProfile(db.ServerProfile row) {
    return ServerProfile(
      id: row.id,
      baseUrl: Uri.parse(row.baseUrl),
      name: row.name,
      userId: row.userId,
      username: row.username,
      deviceId: row.deviceId,
      serverVersion: row.serverVersion,
      allowPrivateHttp: row.allowPrivateHttp,
    );
  }
}

class DriftLibraryRepository implements LibraryRepository {
  const DriftLibraryRepository(this._database, this._gateway);

  final db.AppDatabase _database;
  final JellyfinGateway _gateway;

  @override
  Future<void> cacheLibrary(
    String serverId,
    List<LibraryItem> items,
  ) {
    return _database.replaceLibrary(
      serverId,
      items
          .map(
            (item) => db.CachedItemsCompanion.insert(
              serverId: serverId,
              itemId: item.id,
              itemType: item.type.name,
              name: item.name,
              subtitle: Value(item.subtitle),
              albumId: Value(item.albumId),
              artistId: Value(item.artistId),
              imageUrl: Value(item.imageUrl?.toString()),
              durationMs: Value(item.duration.inMilliseconds),
              indexNumber: Value(item.indexNumber),
              productionYear: Value(item.productionYear),
              isFavorite: Value(item.isFavorite),
              isDownloaded: Value(item.isDownloaded),
              container: Value(item.container),
              updatedAt: DateTime.now(),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<LibraryItem>> readCachedLibrary(String serverId) async {
    final rows = await _database.libraryFor(serverId);
    return rows
        .map(
          (row) => LibraryItem(
            id: row.itemId,
            serverId: row.serverId,
            type: LibraryItemType.values.firstWhere(
              (type) => type.name == row.itemType,
              orElse: () => LibraryItemType.unknown,
            ),
            name: row.name,
            subtitle: row.subtitle,
            albumId: row.albumId,
            artistId: row.artistId,
            imageUrl:
                row.imageUrl == null ? null : Uri.tryParse(row.imageUrl!),
            duration: Duration(milliseconds: row.durationMs),
            indexNumber: row.indexNumber,
            productionYear: row.productionYear,
            isFavorite: row.isFavorite,
            isDownloaded: row.isDownloaded,
            container: row.container,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LibraryItem>> search(
    AuthSession session,
    String query,
  ) {
    return _gateway.fetchLibrary(
      session,
      searchTerm: query,
      limit: 100,
    );
  }

  @override
  Future<List<LibraryItem>> synchronize(AuthSession session) async {
    final items = await _gateway.fetchLibrary(session, limit: 5000);
    await cacheLibrary(session.profile.id, items);
    return items;
  }
}
