@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/ui/widgets/player_bar.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';

import '../support/fakes.dart';

// Rendering differs slightly between operating systems, so these are tagged
// and excluded from CI. Regenerate with `just goldens`.
void main() {
  final tracks = [
    testTrack('1', name: 'Opening'),
    testTrack('2', name: 'Second Song', favorite: true),
    testTrack('3', name: 'Closer'),
  ];
  final snapshot = PlaybackSnapshot(
    queue: PlaybackQueue(items: tracks, currentIndex: 1),
    position: const Duration(seconds: 42),
    playing: true,
  );

  testWidgets('player bar', (tester) async {
    await pumpWithFakes(
      tester,
      const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
      size: Size(1240, PlayerBar.height),
      snapshot: snapshot,
      library: tracks,
    );
    await expectLater(
      find.byType(PlayerBar),
      matchesGoldenFile('player_bar.png'),
    );
  });

  testWidgets('track table', (tester) async {
    await pumpWithFakes(
      tester,
      ListView(
        children: [
          const TrackTableHeader(),
          for (final (index, track) in tracks.indexed)
            TrackRow(index: index + 1, track: track, onTap: () {}),
        ],
      ),
      size: const Size(900, 220),
      snapshot: snapshot,
      library: tracks,
    );
    await expectLater(
      find.byType(ListView),
      matchesGoldenFile('track_table.png'),
    );
  });
}
