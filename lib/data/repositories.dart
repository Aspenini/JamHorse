import 'dart:convert';

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
    await _credentials.writeToken(profile.profileId, session.token);
    try {
      await _database.saveProfile(
        db.ServerProfilesCompanion.insert(
          profileId: profile.profileId,
          serverId: profile.serverId,
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
    } catch (_) {
      await _credentials.deleteToken(profile.profileId);
      rethrow;
    }
  }

  Future<AuthSession?> restore(ServerProfile profile) async {
    final token = await _credentials.readToken(profile.profileId);
    return token == null ? null : AuthSession(profile: profile, token: token);
  }

  Future<void> remove(String profileId) async {
    await _credentials.deleteToken(profileId);
    await _database.removeProfile(profileId);
  }

  Future<void> signOut(String profileId) {
    return _credentials.deleteToken(profileId);
  }

  ServerProfile _mapProfile(db.ServerProfile row) {
    return ServerProfile(
      profileId: row.profileId,
      serverId: row.serverId,
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
  Future<void> cacheLibrary(String profileId, List<LibraryItem> items) {
    return _database.replaceLibrary(
      profileId,
      items
          .map(
            (item) => db.CachedItemsCompanion.insert(
              profileId: profileId,
              serverId: item.serverId,
              itemId: item.id,
              itemType: item.type.name,
              name: item.name,
              subtitle: Value(item.subtitle),
              albumId: Value(item.albumId),
              albumName: Value(item.albumName),
              artistId: Value(item.artistId),
              artistsJson: Value(jsonEncode(item.artists)),
              imageUrl: Value(item.imageUrl?.toString()),
              durationMs: Value(item.duration.inMilliseconds),
              indexNumber: Value(item.indexNumber),
              discNumber: Value(item.discNumber),
              productionYear: Value(item.productionYear),
              isFavorite: Value(item.isFavorite),
              hasPrimaryImage: Value(item.hasPrimaryImage),
              container: Value(item.container),
              updatedAt: DateTime.now(),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<List<LibraryItem>> readCachedLibrary(String profileId) async {
    final rows = await _database.libraryFor(profileId);
    return rows
        .map(
          (row) => LibraryItem(
            id: row.itemId,
            profileId: row.profileId,
            serverId: row.serverId,
            type: LibraryItemType.values.firstWhere(
              (type) => type.name == row.itemType,
              orElse: () => LibraryItemType.unknown,
            ),
            name: row.name,
            subtitle: row.subtitle,
            albumId: row.albumId,
            albumName: row.albumName,
            artistId: row.artistId,
            artists: (jsonDecode(row.artistsJson) as List<dynamic>)
                .whereType<String>()
                .toList(growable: false),
            imageUrl: row.imageUrl == null ? null : Uri.tryParse(row.imageUrl!),
            duration: Duration(milliseconds: row.durationMs),
            indexNumber: row.indexNumber,
            discNumber: row.discNumber,
            productionYear: row.productionYear,
            isFavorite: row.isFavorite,
            hasPrimaryImage: row.hasPrimaryImage,
            container: row.container,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LibraryItem>> search(AuthSession session, String query) {
    return _gateway.fetchLibrary(session, searchTerm: query, limit: 100);
  }

  @override
  Future<List<LibraryItem>> synchronize(
    AuthSession session, {
    OperationContext? context,
  }) async {
    final items = await _gateway.fetchLibrary(
      session,
      limit: 0x7fffffff,
      context: context,
    );
    context?.throwIfObsolete();
    await cacheLibrary(session.profile.profileId, items);
    return items;
  }
}
