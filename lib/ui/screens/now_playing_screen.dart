import 'dart:async';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key, this.initialTab = 'player'});

  final String initialTab;

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  Timer? _sleepTimer;

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = ref.watch(playbackCoordinatorProvider);
    final snapshot =
        ref.watch(playbackSnapshotProvider).value ??
        coordinator.currentSnapshot;
    final item = snapshot.queue.current;
    if (item == null) {
      return const Scaffold(
        body: Center(child: Text('Choose something to play.')),
      );
    }
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            tooltip: 'Output devices',
            onPressed: ref
                .read(platformMediaBridgeProvider)
                .showOutputPicker,
            icon: const Icon(Icons.speaker_group_rounded),
          ),
          PopupMenuButton<int>(
            tooltip: 'Sleep timer',
            icon: const Icon(Icons.bedtime_outlined),
            onSelected: _setSleepTimer,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 15, child: Text('Stop in 15 minutes')),
              PopupMenuItem(value: 30, child: Text('Stop in 30 minutes')),
              PopupMenuItem(value: 60, child: Text('Stop in 1 hour')),
              PopupMenuItem(value: 0, child: Text('Cancel sleep timer')),
            ],
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F3263), Color(0xFF121828), JamColors.ink],
            stops: [0, 0.52, 1],
          ),
        ),
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    Expanded(child: _Player(item: item, snapshot: snapshot)),
                    SizedBox(
                      width: 400,
                      child: _QueueAndLyrics(
                        item: item,
                        snapshot: snapshot,
                        initialTab: widget.initialTab,
                      ),
                    ),
                  ],
                )
              : _Player(
                  item: item,
                  snapshot: snapshot,
                  mobileExtras: _QueueAndLyrics(
                    item: item,
                    snapshot: snapshot,
                    initialTab: widget.initialTab,
                    compact: true,
                  ),
                ),
        ),
      ),
    );
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes > 0) {
      _sleepTimer = Timer(
        Duration(minutes: minutes),
        ref.read(playbackCoordinatorProvider).pause,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          minutes == 0
              ? 'Sleep timer canceled'
              : 'Playback will stop in $minutes minutes',
        ),
      ),
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({
    required this.item,
    required this.snapshot,
    this.mobileExtras,
  });

  final LibraryItem item;
  final PlaybackSnapshot snapshot;
  final Widget? mobileExtras;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(playbackCoordinatorProvider);
    final durationMs = item.duration.inMilliseconds.toDouble();
    final value = snapshot.position.inMilliseconds
        .toDouble()
        .clamp(0, durationMs <= 0 ? 1 : durationMs)
        .toDouble();
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 34),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'art-${item.serverId}-${item.id}',
                child: Artwork(item: item, borderRadius: 26, iconSize: 80),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle ?? 'Unknown artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: JamColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: item.isFavorite ? 'Remove favorite' : 'Favorite',
              onPressed: () =>
                  ref.read(appControllerProvider.notifier).toggleFavorite(item),
              icon: Icon(
                item.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: item.isFavorite ? JamColors.accent : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SeekBar(
          value: value,
          max: durationMs <= 0 ? 1 : durationMs,
          onSeek: (position) =>
              coordinator.seek(Duration(milliseconds: position.round())),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_time(snapshot.position)),
              Text('-${_time(item.duration - snapshot.position)}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Shuffle',
              onPressed: () => coordinator.setShuffle(!snapshot.queue.shuffle),
              color: snapshot.queue.shuffle ? JamColors.accent : null,
              icon: const Icon(Icons.shuffle_rounded),
            ),
            IconButton(
              tooltip: 'Previous',
              iconSize: 38,
              onPressed: coordinator.skipPrevious,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            IconButton.filled(
              tooltip: snapshot.playing ? 'Pause' : 'Play',
              iconSize: 42,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(13),
                backgroundColor: Colors.white,
                foregroundColor: JamColors.ink,
              ),
              onPressed: snapshot.playing
                  ? coordinator.pause
                  : coordinator.play,
              icon: Icon(
                snapshot.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Next',
              iconSize: 38,
              onPressed: coordinator.skipNext,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            IconButton(
              tooltip: 'Repeat',
              onPressed: () {
                final next = switch (snapshot.queue.repeatMode) {
                  RepeatMode.off => RepeatMode.all,
                  RepeatMode.all => RepeatMode.one,
                  RepeatMode.one => RepeatMode.off,
                };
                coordinator.setRepeat(next);
              },
              color: snapshot.queue.repeatMode == RepeatMode.off
                  ? null
                  : JamColors.accent,
              icon: Icon(
                snapshot.queue.repeatMode == RepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
              ),
            ),
          ],
        ),
        if (mobileExtras != null) ...[
          const SizedBox(height: 22),
          mobileExtras!,
        ],
      ],
    );
  }

  static String _time(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({
    required this.value,
    required this.max,
    required this.onSeek,
  });

  final double value;
  final double max;
  final ValueChanged<double> onSeek;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: (_dragValue ?? widget.value).clamp(0, widget.max),
      max: widget.max,
      onChanged: (value) => setState(() => _dragValue = value),
      onChangeEnd: (value) {
        widget.onSeek(value);
        _dragValue = null;
      },
    );
  }
}

class _QueueAndLyrics extends ConsumerWidget {
  const _QueueAndLyrics({
    required this.item,
    required this.snapshot,
    required this.initialTab,
    this.compact = false,
  });

  final LibraryItem item;
  final PlaybackSnapshot snapshot;
  final String initialTab;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyrics = ref.watch(lyricsProvider(item.id));
    final initialIndex = initialTab == 'queue' ? 1 : 0;
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Container(
        margin: EdgeInsets.all(compact ? 0 : 20),
        height: compact ? 410 : null,
        decoration: BoxDecoration(
          color: const Color(0xAA101016),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Lyrics'),
                Tab(text: 'Queue'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  switch (lyrics) {
                    AsyncValue(isLoading: true) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    AsyncValue(value: final lines?)
                        when lines.isNotEmpty =>
                      ListView.builder(
                        padding: const EdgeInsets.all(22),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          final active =
                              line.start != null &&
                              line.start! <= snapshot.position &&
                              (index == lines.length - 1 ||
                                  lines[index + 1].start == null ||
                                  lines[index + 1].start! >
                                      snapshot.position);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Text(
                              line.text,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: active
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                            ),
                          );
                        },
                      ),
                    _ => const Center(
                      child: Text('No lyrics on this server'),
                    ),
                  },
                  ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: snapshot.queue.items.length,
                    itemBuilder: (context, index) {
                      final queued = snapshot.queue.items[index];
                      return ListTile(
                        selected: index == snapshot.queue.currentIndex,
                        selectedColor: JamColors.accentBright,
                        leading: SizedBox.square(
                          dimension: 42,
                          child: Artwork(
                            item: queued,
                            borderRadius: 8,
                            iconSize: 20,
                          ),
                        ),
                        title: Text(
                          queued.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          queued.subtitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
