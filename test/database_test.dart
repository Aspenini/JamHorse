import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/data/database.dart';

void main() {
  test('cached libraries remain isolated by server', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026);
    await database.replaceLibrary('profile-a', [
      CachedItemsCompanion.insert(
        profileId: 'profile-a',
        serverId: 'server-a',
        itemId: 'track-1',
        itemType: 'track',
        name: 'One',
        updatedAt: now,
      ),
    ]);
    await database.replaceLibrary('profile-b', [
      CachedItemsCompanion.insert(
        profileId: 'profile-b',
        serverId: 'server-b',
        itemId: 'track-2',
        itemType: 'track',
        name: 'Two',
        updatedAt: now,
        isFavorite: const Value(true),
      ),
    ]);

    expect((await database.libraryFor('profile-a')).single.name, 'One');
    expect((await database.libraryFor('profile-b')).single.name, 'Two');
  });

  test(
    'profiles on the same remote server remain separate identities',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      for (final (profileId, userId) in [
        ('profile-a', 'user-a'),
        ('profile-b', 'user-b'),
      ]) {
        await database.saveProfile(
          ServerProfilesCompanion.insert(
            profileId: profileId,
            serverId: 'same-server',
            baseUrl: 'https://music.example.com',
            name: 'Music',
            userId: userId,
            username: userId,
            deviceId: 'device',
            serverVersion: '10.10.0',
            lastUsedAt: DateTime(2026),
          ),
        );
      }

      final profiles = await database.allProfiles();
      expect(
        profiles.map((profile) => profile.profileId),
        containsAll(['profile-a', 'profile-b']),
      );
    },
  );

  test('liking an item updates its cached row in place', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.replaceLibrary('profile', [
      for (final id in ['a', 'b'])
        CachedItemsCompanion.insert(
          profileId: 'profile',
          serverId: 'server',
          itemId: id,
          itemType: 'track',
          name: id,
          updatedAt: DateTime(2026),
        ),
    ]);

    await database.setCachedFavorite('profile', 'b', true);

    final rows = await database.libraryFor('profile');
    expect(
      {for (final row in rows) row.itemId: row.isFavorite},
      {'a': false, 'b': true},
    );
  });

  test('saving playback position leaves the queue untouched', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.replaceQueue('profile', [
      for (var index = 0; index < 3; index++)
        QueueEntriesCompanion.insert(
          profileId: 'profile',
          queueIndex: index,
          itemId: 'track-$index',
        ),
    ], PlaybackStatesCompanion.insert(profileId: 'profile'));

    await database.savePlaybackState(
      PlaybackStatesCompanion.insert(
        profileId: 'profile',
        currentIndex: const Value(2),
        positionMs: const Value(5000),
      ),
    );

    expect(await database.queueFor('profile'), hasLength(3));
    final state = await database.playbackStateFor('profile');
    expect(state?.currentIndex, 2);
    expect(state?.positionMs, 5000);
  });

  test('version 2 databases migrate to version 3 keeping their data', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          for (final statement in _version2Schema) {
            raw.execute(statement);
          }
          raw
            ..execute(
              "INSERT INTO download_entries (id, profile_id, item_id, status, "
              "file_path, progress, size_bytes, checksum, updated_at) VALUES "
              "('dl', 'profile', 'track', 'complete', '/music/track.flac', 1, "
              "10, 'unused', 0)",
            )
            ..execute(
              "INSERT INTO cached_items (profile_id, server_id, item_id, "
              "item_type, name, updated_at) VALUES "
              "('profile', 'server', 'track', 'track', 'Song', 0)",
            )
            ..execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(database.close);

    expect(await database.completedDownloadPaths('profile'), {
      'track': '/music/track.flac',
    });
    final cached = (await database.libraryFor('profile')).single;
    expect(cached.name, 'Song');
    expect(cached.dateCreated, isNull);
    final columns = await database
        .customSelect("PRAGMA table_info('download_entries')")
        .map((row) => row.read<String>('name'))
        .get();
    expect(columns, isNot(contains('checksum')));
    final indexes = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'download_entries_profile_item'",
        )
        .get();
    expect(indexes, hasLength(1));
  });

  test(
    'forgetting a profile removes all of its persisted state only',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      for (final profileId in ['profile-a', 'profile-b']) {
        await database.replaceQueue(profileId, [
          QueueEntriesCompanion.insert(
            profileId: profileId,
            queueIndex: 0,
            itemId: 'track-$profileId',
          ),
        ], PlaybackStatesCompanion.insert(profileId: profileId));
      }

      await database.removeProfile('profile-a');

      expect(await database.queueFor('profile-a'), isEmpty);
      expect(await database.playbackStateFor('profile-a'), isNull);
      expect(await database.queueFor('profile-b'), hasLength(1));
      expect(await database.playbackStateFor('profile-b'), isNotNull);
    },
  );
}

/// The schema as shipped at version 2, captured from sqlite_master.
const _version2Schema = [
  'CREATE TABLE "server_profiles" ("profile_id" TEXT NOT NULL, "server_id" TEXT NOT NULL, "base_url" TEXT NOT NULL, "name" TEXT NOT NULL, "user_id" TEXT NOT NULL, "username" TEXT NOT NULL, "device_id" TEXT NOT NULL, "server_version" TEXT NOT NULL, "allow_private_http" INTEGER NOT NULL DEFAULT 0 CHECK ("allow_private_http" IN (0, 1)), "last_used_at" INTEGER NOT NULL, PRIMARY KEY ("profile_id"))',
  'CREATE TABLE "cached_items" ("profile_id" TEXT NOT NULL, "server_id" TEXT NOT NULL, "item_id" TEXT NOT NULL, "item_type" TEXT NOT NULL, "name" TEXT NOT NULL, "subtitle" TEXT NULL, "album_id" TEXT NULL, "album_name" TEXT NULL, "artist_id" TEXT NULL, "artists_json" TEXT NOT NULL DEFAULT \'[]\', "image_url" TEXT NULL, "duration_ms" INTEGER NOT NULL DEFAULT 0, "index_number" INTEGER NULL, "disc_number" INTEGER NULL, "production_year" INTEGER NULL, "is_favorite" INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)), "has_primary_image" INTEGER NOT NULL DEFAULT 0 CHECK ("has_primary_image" IN (0, 1)), "container" TEXT NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("profile_id", "item_id"))',
  'CREATE TABLE "download_entries" ("id" TEXT NOT NULL, "profile_id" TEXT NOT NULL, "item_id" TEXT NOT NULL, "status" TEXT NOT NULL, "file_path" TEXT NULL, "progress" REAL NOT NULL DEFAULT 0.0, "size_bytes" INTEGER NOT NULL DEFAULT 0, "checksum" TEXT NULL, "last_played_at" INTEGER NULL, "updated_at" INTEGER NOT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "queue_entries" ("profile_id" TEXT NOT NULL, "queue_index" INTEGER NOT NULL, "item_id" TEXT NOT NULL, "is_current" INTEGER NOT NULL DEFAULT 0 CHECK ("is_current" IN (0, 1)), PRIMARY KEY ("profile_id", "queue_index"))',
  'CREATE TABLE "playback_states" ("profile_id" TEXT NOT NULL, "current_index" INTEGER NOT NULL DEFAULT -1, "position_ms" INTEGER NOT NULL DEFAULT 0, "shuffle" INTEGER NOT NULL DEFAULT 0 CHECK ("shuffle" IN (0, 1)), "repeat_mode" TEXT NOT NULL DEFAULT \'off\', "sleep_deadline" INTEGER NULL, PRIMARY KEY ("profile_id"))',
  'CREATE TABLE "pending_reports" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "profile_id" TEXT NOT NULL, "item_id" TEXT NOT NULL, "play_session_id" TEXT NOT NULL, "event_type" TEXT NOT NULL, "position_ms" INTEGER NOT NULL, "payload_json" TEXT NOT NULL, "created_at" INTEGER NOT NULL)',
];
