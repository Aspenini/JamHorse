import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/data/database.dart';

void main() {
  test('cached libraries remain isolated by server', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026);
    await database.replaceLibrary('server-a', [
      CachedItemsCompanion.insert(
        serverId: 'server-a',
        itemId: 'track-1',
        itemType: 'track',
        name: 'One',
        updatedAt: now,
      ),
    ]);
    await database.replaceLibrary('server-b', [
      CachedItemsCompanion.insert(
        serverId: 'server-b',
        itemId: 'track-2',
        itemType: 'track',
        name: 'Two',
        updatedAt: now,
        isFavorite: const Value(true),
      ),
    ]);

    expect((await database.libraryFor('server-a')).single.name, 'One');
    expect((await database.libraryFor('server-b')).single.name, 'Two');
  });
}
