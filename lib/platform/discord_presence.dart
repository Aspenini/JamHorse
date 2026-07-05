import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application ID from https://discord.com/developers/applications — the
/// application's name is what Discord shows after "Listening to". This is a
/// public identifier, not a secret; override it at build time with
/// `--dart-define=JAMHORSE_DISCORD_APP_ID=<id>` to present as your own app.
const discordApplicationId = String.fromEnvironment(
  'JAMHORSE_DISCORD_APP_ID',
  defaultValue: '1523375346047783002',
);

bool get supportsDiscordPresence =>
    discordApplicationId.isNotEmpty &&
    (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

const _preferenceKey = 'discordPresenceEnabled';
var _initialEnabled = true;

Future<bool> loadDiscordPresenceEnabled() async {
  if (!supportsDiscordPresence) return false;
  final preferences = await SharedPreferences.getInstance();
  return preferences.getBool(_preferenceKey) ?? true;
}

void seedDiscordPresenceEnabled(bool enabled) {
  _initialEnabled = enabled;
}

final discordPresenceProvider =
    NotifierProvider<DiscordPresenceController, bool>(
      DiscordPresenceController.new,
    );

class DiscordPresenceController extends Notifier<bool> {
  DiscordPresenceEngine? _engine;
  StreamSubscription<PlaybackSnapshot>? _subscription;

  @override
  bool build() {
    ref.onDispose(_stop);
    final enabled = supportsDiscordPresence && _initialEnabled;
    if (enabled) _start();
    return enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    if (!supportsDiscordPresence || state == enabled) return;
    state = enabled;
    if (enabled) {
      _start();
    } else {
      _stop();
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, enabled);
  }

  void _start() {
    final coordinator = ref.read(playbackCoordinatorProvider);
    final engine = DiscordPresenceEngine(discordApplicationId);
    _engine = engine;
    _subscription = coordinator.snapshots.listen(engine.update);
    engine.update(coordinator.currentSnapshot);
  }

  void _stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _engine?.dispose();
    _engine = null;
  }
}

/// Turns playback snapshots into Discord "Listening to …" activity updates,
/// deduplicating and rate limiting so steady playback sends nothing and a
/// burst of snapshots collapses into one update.
class DiscordPresenceEngine {
  DiscordPresenceEngine(this.applicationId);

  final String applicationId;

  static const _minSendGap = Duration(seconds: 2);
  static const _reconnectBackoff = Duration(seconds: 20);

  _DiscordIpcConnection? _connection;
  Future<void> _work = Future.value();
  Timer? _trailing;
  PlaybackSnapshot _latest = const PlaybackSnapshot();
  String? _sentSignature;
  DateTime _sentAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _nextConnectAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  void update(PlaybackSnapshot snapshot) {
    if (_disposed) return;
    _latest = snapshot;
    final wait = _minSendGap - DateTime.now().difference(_sentAt);
    if (wait.isNegative) {
      _trailing?.cancel();
      _trailing = null;
      _enqueueSend();
    } else {
      // Collapse the burst into one trailing update.
      _trailing ??= Timer(wait, () {
        _trailing = null;
        _enqueueSend();
      });
    }
  }

  void dispose() {
    _disposed = true;
    _trailing?.cancel();
    _work = _work.then((_) async {
      await _connection?.close();
      _connection = null;
    });
  }

  void _enqueueSend() {
    _work = _work.then((_) => _send()).catchError((Object error) {
      appLog.fine('Discord presence update failed: $error');
      unawaited(_connection?.close());
      _connection = null;
      _sentSignature = null;
      _nextConnectAttempt = DateTime.now().add(_reconnectBackoff);
    });
  }

  Future<void> _send() async {
    if (_disposed) return;
    final now = DateTime.now();
    final activity = buildDiscordActivity(_latest, now);
    final signature = discordActivitySignature(_latest, now);
    if (signature == _sentSignature) return;
    if (_connection == null) {
      // Nothing to show and no connection: don't wake Discord up for it.
      if (activity == null) return;
      if (now.isBefore(_nextConnectAttempt)) return;
      _nextConnectAttempt = now.add(_reconnectBackoff);
      _connection = await _DiscordIpcConnection.open(applicationId);
      if (_connection == null) return;
      appLog.info('Discord presence connected');
    }
    await _connection!.setActivity(activity);
    _sentSignature = signature;
    _sentAt = DateTime.now();
  }
}

/// The activity payload for a snapshot, or null when nothing should show
/// (nothing queued, or paused — Discord has no paused state, so like Spotify
/// the presence disappears while paused).
Map<String, dynamic>? buildDiscordActivity(
  PlaybackSnapshot snapshot,
  DateTime now,
) {
  final item = snapshot.queue.current;
  if (item == null || !snapshot.playing) return null;
  final artists = item.artists.isNotEmpty
      ? item.artists.join(', ')
      : item.subtitle;
  final start = now.subtract(snapshot.position);
  return {
    'type': 2, // Listening
    'details': _clampText(item.name),
    if (artists != null && artists.isNotEmpty) 'state': _clampText(artists),
    'timestamps': {
      'start': start.millisecondsSinceEpoch,
      if (item.duration > Duration.zero)
        'end': start.add(item.duration).millisecondsSinceEpoch,
    },
    if (item.imageUrl != null)
      'assets': {
        'large_image': item.imageUrl.toString(),
        if (item.albumName != null && item.albumName!.isNotEmpty)
          'large_text': _clampText(item.albumName!),
      },
  };
}

/// Stable fingerprint of what would be shown; the start timestamp is bucketed
/// so position jitter between snapshots doesn't count as a change but a seek
/// does.
String discordActivitySignature(PlaybackSnapshot snapshot, DateTime now) {
  final item = snapshot.queue.current;
  if (item == null || !snapshot.playing) return 'idle';
  final startBucket =
      now.subtract(snapshot.position).millisecondsSinceEpoch ~/ 5000;
  return '${item.profileId}/${item.id}/$startBucket';
}

// Discord requires activity strings to be 2-128 characters.
String _clampText(String value) {
  if (value.length < 2) return value.padRight(2);
  return value.substring(0, min(value.length, 128));
}

Uint8List encodeDiscordFrame(int opcode, Map<String, dynamic> payload) {
  final body = utf8.encode(jsonEncode(payload));
  final frame = Uint8List(8 + body.length);
  frame.buffer.asByteData()
    ..setUint32(0, opcode, Endian.little)
    ..setUint32(4, body.length, Endian.little);
  frame.setRange(8, frame.length, body);
  return frame;
}

const _opHandshake = 0;
const _opFrame = 1;
const _opClose = 2;

/// One handshaken connection to the local Discord client's IPC endpoint.
///
/// Every command receives exactly one response frame, so the transport is
/// driven strictly write-then-read; that keeps the Windows named pipe (a
/// single [RandomAccessFile] that cannot read and write concurrently) and the
/// unix socket behind one implementation.
class _DiscordIpcConnection {
  _DiscordIpcConnection._(this._transport);

  final _IpcTransport _transport;
  var _nonce = 0;

  static Future<_DiscordIpcConnection?> open(String applicationId) async {
    for (var slot = 0; slot < 10; slot++) {
      final _IpcTransport? transport;
      try {
        transport = await _IpcTransport.open(slot);
      } on Exception {
        continue;
      }
      if (transport == null) continue;
      final connection = _DiscordIpcConnection._(transport);
      try {
        final response = await connection._exchange(_opHandshake, {
          'v': 1,
          'client_id': applicationId,
        });
        if (response.$1 == _opFrame) return connection;
        appLog.warning('Discord IPC handshake rejected: ${response.$2}');
      } on Exception catch (error) {
        appLog.fine('Discord IPC handshake failed on slot $slot: $error');
      }
      await connection.close();
      return null;
    }
    return null;
  }

  Future<void> setActivity(Map<String, dynamic>? activity) async {
    final response = await _exchange(_opFrame, {
      'cmd': 'SET_ACTIVITY',
      'nonce': '${++_nonce}',
      'args': {'pid': pid, 'activity': ?activity},
    });
    if (response.$1 != _opFrame) {
      throw const SocketException('Discord IPC connection closed');
    }
    final body = response.$2;
    if (body['evt'] == 'ERROR') {
      appLog.warning('Discord rejected activity: ${body['data']}');
    }
  }

  Future<(int, Map<String, dynamic>)> _exchange(
    int opcode,
    Map<String, dynamic> payload,
  ) async {
    await _transport.write(encodeDiscordFrame(opcode, payload));
    final header = await _transport.read(8);
    final view = ByteData.sublistView(header);
    final responseOpcode = view.getUint32(0, Endian.little);
    final length = view.getUint32(4, Endian.little);
    final body = await _transport.read(length);
    return (
      responseOpcode,
      jsonDecode(utf8.decode(body)) as Map<String, dynamic>,
    );
  }

  Future<void> close() async {
    try {
      await _transport.write(encodeDiscordFrame(_opClose, {}));
    } on Exception {
      // The pipe may already be gone; closing is best-effort.
    }
    await _transport.dispose();
  }
}

abstract interface class _IpcTransport {
  static Future<_IpcTransport?> open(int slot) async {
    if (Platform.isWindows) {
      // \\?\ instead of \\.\ because dart:io rejects device namespace paths.
      final file = await File(
        '\\\\?\\pipe\\discord-ipc-$slot',
      ).open(mode: FileMode.append);
      return _PipeFileTransport(file);
    }
    final directory =
        Platform.environment['XDG_RUNTIME_DIR'] ??
        Platform.environment['TMPDIR'] ??
        Platform.environment['TMP'] ??
        '/tmp';
    final path = '$directory/discord-ipc-$slot';
    if (!File(path).existsSync()) return null;
    final socket = await Socket.connect(
      InternetAddress(path, type: InternetAddressType.unix),
      0,
    );
    return _SocketTransport(socket);
  }

  Future<void> write(Uint8List bytes);

  /// Reads exactly [length] bytes.
  Future<Uint8List> read(int length);

  Future<void> dispose();
}

class _PipeFileTransport implements _IpcTransport {
  _PipeFileTransport(this._file);

  final RandomAccessFile _file;

  @override
  Future<void> write(Uint8List bytes) => _file.writeFrom(bytes);

  @override
  Future<Uint8List> read(int length) async {
    final builder = BytesBuilder(copy: false);
    while (builder.length < length) {
      final chunk = await _file.read(length - builder.length);
      if (chunk.isEmpty) {
        throw const SocketException('Discord IPC pipe closed');
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  Future<void> dispose() => _file.close();
}

class _SocketTransport implements _IpcTransport {
  _SocketTransport(this._socket) {
    _socket.listen(
      _buffer.add,
      onDone: () => _closed = true,
      onError: (Object _) => _closed = true,
    );
  }

  final Socket _socket;
  final _buffer = BytesBuilder();
  bool _closed = false;

  @override
  Future<void> write(Uint8List bytes) async {
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<Uint8List> read(int length) async {
    while (_buffer.length < length) {
      if (_closed) throw const SocketException('Discord IPC socket closed');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final bytes = _buffer.takeBytes();
    _buffer.add(bytes.sublist(length));
    return Uint8List.sublistView(bytes, 0, length);
  }

  @override
  Future<void> dispose() async {
    await _socket.close();
  }
}
