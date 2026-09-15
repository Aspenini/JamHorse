import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/ui_state.dart';
import 'package:jamhorse/ui/widgets/player_bar.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';

import 'support/fakes.dart';

void main() {
  final tracks = [
    testTrack('1', name: 'Opening'),
    testTrack('2', name: 'Second Song', favorite: true),
    testTrack('3', name: 'Closer'),
  ];
  PlaybackSnapshot playing(int index, {bool isPlaying = true}) {
    return PlaybackSnapshot(
      queue: PlaybackQueue(items: tracks, currentIndex: index),
      position: const Duration(seconds: 42),
      playing: isPlaying,
    );
  }

  group('PlayerBar', () {
    for (final width in [920.0, 1240.0, 1920.0]) {
      testWidgets('lays out without overflow at ${width.round()}px', (
        tester,
      ) async {
        await pumpWithFakes(
          tester,
          const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
          size: Size(width, 300),
          snapshot: playing(1),
          library: tracks,
        );
        expect(find.text('Second Song'), findsOneWidget);
        expect(find.text('The Band'), findsOneWidget);
        expect(find.text('0:42'), findsOneWidget);
      });
    }

    testWidgets('transport buttons drive the coordinator', (tester) async {
      final coordinator = await pumpWithFakes(
        tester,
        const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
        snapshot: playing(0, isPlaying: false),
        library: tracks,
      );

      await tester.tap(find.byTooltip('Play'));
      await tester.tap(find.byTooltip('Next'));
      await tester.tap(find.byTooltip('Enable shuffle'));
      await tester.pump();

      expect(coordinator.calls, ['play', 'next', 'shuffle:true']);
    });

    testWidgets('panel buttons toggle the right-hand panel', (tester) async {
      await pumpWithFakes(
        tester,
        const Align(alignment: Alignment.bottomCenter, child: PlayerBar()),
        snapshot: playing(0),
        library: tracks,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlayerBar)),
      );

      await tester.tap(find.byTooltip('Queue'));
      await tester.pump();
      expect(container.read(rightPanelProvider), RightPanelView.queue);

      await tester.tap(find.byTooltip('Queue'));
      await tester.pump();
      expect(container.read(rightPanelProvider), isNull);
    });
  });

  group('TrackRow', () {
    Widget table(void Function(LibraryItem) onTap) => ListView(
      children: [
        const TrackTableHeader(),
        for (final (index, track) in tracks.indexed)
          TrackRow(index: index + 1, track: track, onTap: () => onTap(track)),
      ],
    );

    testWidgets('the playing track shows an equalizer instead of its number', (
      tester,
    ) async {
      await pumpWithFakes(
        tester,
        table((_) {}),
        snapshot: playing(1),
        library: tracks,
      );

      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(find.text('3:21'), findsNWidgets(3));
    });

    testWidgets('tapping a row plays it and liked rows show a heart', (
      tester,
    ) async {
      final tapped = <String>[];
      await pumpWithFakes(
        tester,
        table((t) => tapped.add(t.id)),
        library: tracks,
      );

      await tester.tap(find.text('Closer'));
      await tester.pump();

      expect(tapped, ['3']);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}
