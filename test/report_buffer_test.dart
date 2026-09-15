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
    final inner = _RecordingReporter()..fail = true;
    final reporter = BufferedPlaybackReporter(inner, database);

    await reporter.reportPlaybackStarted(
      _session,
      _item,
      playSessionId: 'play',
    );
    expect(await database.oldestPendingReports('profile'), hasLength(1));

    inner.fail = false;
    await reporter.reportPlaybackStopped(
      _session,
      _item,
      const Duration(seconds: 9),
      playSessionId: 'play',
    );

    expect(inner.events, ['started:play', 'stopped:play:9000']);
    expect(await database.oldestPendingReports('profile'), isEmpty);
  });

  test('overlapping report calls are serialized', () async {
    final inner = _RecordingReporter(delay: const Duration(milliseconds: 5));
    final reporter = BufferedPlaybackReporter(inner, database);

    await Future.wait([
      reporter.reportPlaybackStarted(_session, _item),
      reporter.reportPlaybackProgress(
        _session,
        _item,
        const Duration(seconds: 1),
        paused: false,
        playSessionId: 'play',
      ),
      reporter.reportPlaybackStopped(
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
    final inner = _RecordingReporter();
    final reporter = BufferedPlaybackReporter(inner, database);

    await reporter.reportPlaybackProgress(
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

class _RecordingReporter implements PlaybackReporter {
  _RecordingReporter({this.delay = Duration.zero});

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
      if (fail) throw const _OfflineForTest();
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
}

class _OfflineForTest implements Exception {
  const _OfflineForTest();
}
