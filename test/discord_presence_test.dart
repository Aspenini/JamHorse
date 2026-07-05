import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/platform/discord_presence.dart';

LibraryItem _track({Duration duration = const Duration(minutes: 3)}) {
  return LibraryItem(
    id: 'track-1',
    profileId: 'profile-1',
    serverId: 'server-1',
    type: LibraryItemType.track,
    name: 'Test Track',
    albumName: 'Test Album',
    artists: const ['Test Artist'],
    imageUrl: Uri.parse('https://music.example.com/Items/track-1/Primary'),
    duration: duration,
  );
}

PlaybackSnapshot _snapshot({
  LibraryItem? item,
  bool playing = true,
  Duration position = const Duration(seconds: 30),
}) {
  return PlaybackSnapshot(
    queue: PlaybackQueue(
      items: item == null ? const [] : [item],
      currentIndex: item == null ? -1 : 0,
    ),
    position: position,
    playing: playing,
  );
}

void main() {
  final now = DateTime.utc(2026, 7, 5, 12);

  test('playing track becomes a Listening activity with progress and art', () {
    final activity = buildDiscordActivity(_snapshot(item: _track()), now)!;

    expect(activity['type'], 2);
    expect(activity['details'], 'Test Track');
    expect(activity['state'], 'Test Artist');
    final timestamps = activity['timestamps'] as Map<String, dynamic>;
    final start = now
        .subtract(const Duration(seconds: 30))
        .millisecondsSinceEpoch;
    expect(timestamps['start'], start);
    expect(
      timestamps['end'],
      start + const Duration(minutes: 3).inMilliseconds,
    );
    final assets = activity['assets'] as Map<String, dynamic>;
    expect(
      assets['large_image'],
      'https://music.example.com/Items/track-1/Primary',
    );
    expect(assets['large_text'], 'Test Album');
  });

  test('unknown duration omits the end timestamp', () {
    final activity = buildDiscordActivity(
      _snapshot(item: _track(duration: Duration.zero)),
      now,
    )!;

    final timestamps = activity['timestamps'] as Map<String, dynamic>;
    expect(timestamps.containsKey('end'), isFalse);
  });

  test('paused or empty playback shows nothing', () {
    expect(buildDiscordActivity(_snapshot(item: null), now), isNull);
    expect(
      buildDiscordActivity(_snapshot(item: _track(), playing: false), now),
      isNull,
    );
  });

  test('signature is stable across position jitter but not across seeks', () {
    final steady = discordActivitySignature(_snapshot(item: _track()), now);
    final jitter = discordActivitySignature(
      _snapshot(item: _track(), position: const Duration(seconds: 31)),
      now.add(const Duration(seconds: 1)),
    );
    final seek = discordActivitySignature(
      _snapshot(item: _track(), position: const Duration(minutes: 2)),
      now,
    );
    final paused = discordActivitySignature(
      _snapshot(item: _track(), playing: false),
      now,
    );

    expect(jitter, steady);
    expect(seek, isNot(steady));
    expect(paused, 'idle');
  });

  test('frames are little-endian opcode, length, then JSON body', () {
    final frame = encodeDiscordFrame(1, {'cmd': 'SET_ACTIVITY'});

    final view = ByteData.sublistView(frame);
    expect(view.getUint32(0, Endian.little), 1);
    expect(view.getUint32(4, Endian.little), frame.length - 8);
    expect(jsonDecode(utf8.decode(frame.sublist(8))), {'cmd': 'SET_ACTIVITY'});
  });
}
