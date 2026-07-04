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
