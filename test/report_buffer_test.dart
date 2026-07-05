import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/data/database.dart' hide ServerProfile;
import 'package:jamhorse/data/report_buffer.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('offline reports do not throw and flush in start/stop order', () async {
    final inner = _RecordingGateway()..fail = true;
    final gateway = ReportBufferingGateway(inner, database);

    await gateway.reportPlaybackStarted(_session, _item, playSessionId: 'play');
    expect(await database.oldestPendingReports('profile'), hasLength(1));

    inner.fail = false;
    await gateway.reportPlaybackStopped(
      _session,
      _item,
      const Duration(seconds: 9),
      playSessionId: 'play',
    );

    expect(inner.events, ['started:play', 'stopped:play:9000']);
    expect(await database.oldestPendingReports('profile'), isEmpty);
  });

  test('overlapping report calls are serialized', () async {
    final inner = _RecordingGateway(delay: const Duration(milliseconds: 5));
    final gateway = ReportBufferingGateway(inner, database);

    await Future.wait([
      gateway.reportPlaybackStarted(_session, _item),
      gateway.reportPlaybackProgress(
        _session,
        _item,
        const Duration(seconds: 1),
        paused: false,
        playSessionId: 'play',
      ),
      gateway.reportPlaybackStopped(
        _session,
        _item,
        const Duration(seconds: 2),
        playSessionId: 'play',
      ),
    ]);

    expect(inner.maxInFlight, 1);
    expect(inner.events, [
      'started:device-track',
      'progress:play:1000:false',
      'stopped:play:2000',
    ]);
  });

  test('corrupt queued metadata cannot poison later reports', () async {
    await database.insertPendingReport(
      PendingReportsCompanion.insert(
        profileId: 'profile',
        itemId: 'track',
        playSessionId: 'old-play',
        eventType: 'progress',
        positionMs: 4000,
        payloadJson: 'not-json',
        createdAt: DateTime(2026),
      ),
    );
    final inner = _RecordingGateway();
    final gateway = ReportBufferingGateway(inner, database);

    await gateway.reportPlaybackProgress(
      _session,
      _item,
      const Duration(seconds: 5),
      paused: false,
      playSessionId: 'new-play',
    );

    expect(inner.events, [
      'progress:old-play:4000:true',
      'progress:new-play:5000:false',
    ]);
    expect(await database.oldestPendingReports('profile'), isEmpty);
  });

  test('non-reporting gateway operations pass through unchanged', () async {
    final inner = _ForwardingGateway();
    final gateway = ReportBufferingGateway(inner, database);

    expect(
      (await gateway.inspectServer(_session.profile.baseUrl)).id,
      'server',
    );
    expect(
      (await gateway.authenticate(
        baseUrl: _session.profile.baseUrl,
        username: 'listener',
        password: 'password',
        deviceId: 'device',
        allowPrivateHttp: false,
      )).token,
      'secret',
    );
    expect((await gateway.fetchLibraryPage(_session)).items, [_item]);
    expect(await gateway.fetchFavorites(_session), [_item]);
    expect(await gateway.fetchRecentlyPlayed(_session), [_item]);
    expect((await gateway.fetchLyrics(_session, 'track')).single.text, 'line');
    await gateway.setFavorite(_session, 'track', true);
    expect(gateway.imageUri(_session, 'track').path, '/image/track');
    expect(gateway.userImageUri(_session).path, '/user-image/user');
    expect(gateway.streamUri(_session, _item).path, '/stream/track');
    expect(gateway.playbackHeaders(_session), {'Authorization': 'secret'});
    expect(inner.favorite, isTrue);
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

const _item = LibraryItem(
  id: 'track',
  profileId: 'profile',
  serverId: 'server',
  type: LibraryItemType.track,
  name: 'Song',
);

class _RecordingGateway implements JellyfinGateway {
  _RecordingGateway({this.delay = Duration.zero});

  final Duration delay;
  final events = <String>[];
  bool fail = false;
  int _inFlight = 0;
  int maxInFlight = 0;

  Future<void> _record(String value) async {
    _inFlight++;
    if (_inFlight > maxInFlight) maxInFlight = _inFlight;
    try {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      if (fail) throw const SocketExceptionForTest();
      events.add(value);
    } finally {
      _inFlight--;
    }
  }

  @override
  Future<void> reportPlaybackStarted(
    AuthSession session,
    LibraryItem item, {
    String? playSessionId,
  }) => _record('started:$playSessionId');

  @override
  Future<void> reportPlaybackProgress(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    required bool paused,
    String? playSessionId,
  }) => _record('progress:$playSessionId:${position.inMilliseconds}:$paused');

  @override
  Future<void> reportPlaybackStopped(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    String? playSessionId,
  }) => _record('stopped:$playSessionId:${position.inMilliseconds}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SocketExceptionForTest implements Exception {
  const SocketExceptionForTest();
}

class _ForwardingGateway extends _RecordingGateway {
  bool favorite = false;

  @override
  Future<ServerInfo> inspectServer(Uri baseUrl) async =>
      const ServerInfo(id: 'server', name: 'Music', version: '10.10.0');

  @override
  Future<AuthSession> authenticate({
    required Uri baseUrl,
    required String username,
    required String password,
    required String deviceId,
    required bool allowPrivateHttp,
  }) async => _session;

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
  }) async =>
      const LibraryPage(items: [_item], startIndex: 0, totalRecordCount: 1);

  @override
  Future<List<LibraryItem>> fetchFavorites(AuthSession session) async => [
    _item,
  ];

  @override
  Future<List<LibraryItem>> fetchRecentlyPlayed(AuthSession session) async => [
    _item,
  ];

  @override
  Future<List<LyricsLine>> fetchLyrics(
    AuthSession session,
    String itemId,
  ) async => const [LyricsLine(text: 'line')];

  @override
  Future<void> setFavorite(
    AuthSession session,
    String itemId,
    bool favorite,
  ) async {
    this.favorite = favorite;
  }

  @override
  Uri imageUri(AuthSession session, String itemId, {int width = 600}) =>
      Uri.parse('https://music.example.com/image/$itemId');

  @override
  Uri userImageUri(AuthSession session, {int width = 128}) => Uri.parse(
    'https://music.example.com/user-image/${session.profile.userId}',
  );

  @override
  Uri streamUri(AuthSession session, LibraryItem item, {int? maxBitrate}) =>
      Uri.parse('https://music.example.com/stream/${item.id}');

  @override
  Map<String, String> playbackHeaders(AuthSession session) => {
    'Authorization': session.token,
  };
}
