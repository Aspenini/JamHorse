import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';

void main() {
  test('library pagination advances until Jellyfin total is reached', () async {
    final gateway = _PagingGateway(total: 5);

    final items = await gateway.fetchLibrary(_session, limit: 20);

    expect(items.map((item) => item.id), ['0', '1', '2', '3', '4']);
    expect(gateway.startIndexes, [0, 2, 4]);
    expect(() => items.add(_item(9)), throwsUnsupportedError);
  });

  test(
    'library pagination stops at caller limit without an extra page',
    () async {
      final gateway = _PagingGateway(total: null);

      final items = await gateway.fetchLibrary(_session, limit: 3);

      expect(items, hasLength(3));
      expect(gateway.startIndexes, [0, 2]);
      expect(gateway.requestedLimits, [3, 1]);
    },
  );

  test('obsolete operation is discarded before requesting a page', () {
    final gateway = _PagingGateway(total: 5);
    final context = OperationContext(
      profileId: 'profile',
      generation: 2,
      isCurrentCallback: () => false,
    );

    expect(
      () => gateway.fetchLibrary(_session, limit: 20, context: context),
      throwsA(isA<ObsoleteOperation>()),
    );
    expect(gateway.startIndexes, isEmpty);
  });
}

final _session = AuthSession(
  profile: ServerProfile(
    profileId: 'profile',
    serverId: 'server',
    baseUrl: Uri.parse('https://music.example.com'),
    name: 'Music',
    userId: 'user',
    username: 'listener',
    deviceId: 'device',
    serverVersion: '10.10.0',
  ),
  token: 'secret',
);

LibraryItem _item(int index) => LibraryItem(
  id: '$index',
  profileId: 'profile',
  serverId: 'server',
  type: LibraryItemType.track,
  name: 'Track $index',
);

class _PagingGateway implements JellyfinGateway {
  _PagingGateway({required this.total});

  final int? total;
  final startIndexes = <int>[];
  final requestedLimits = <int>[];

  @override
  Future<LibraryPage> fetchLibraryPage(
    AuthSession session, {
    Set<LibraryItemType> types = const {},
    int limit = 200,
    String? parentId,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
    int startIndex = 0,
    OperationContext? context,
  }) async {
    startIndexes.add(startIndex);
    requestedLimits.add(limit);
    final remaining = total == null ? limit : total! - startIndex;
    final length = remaining.clamp(0, limit < 2 ? limit : 2);
    return LibraryPage(
      items: List.generate(length, (offset) => _item(startIndex + offset)),
      startIndex: startIndex,
      totalRecordCount: total,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
