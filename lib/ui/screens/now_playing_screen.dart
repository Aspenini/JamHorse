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
  @override
  Widget build(BuildContext context) {
    final coordinator = ref.watch(playbackCoordinatorProvider);
    final localSnapshot =
        ref.watch(playbackSnapshotProvider).value ??
        coordinator.currentSnapshot;
    final bridge = ref.watch(platformMediaBridgeProvider);
    final capabilities =
        ref.watch(platformCapabilitiesProvider).value ?? bridge.capabilities;
    final remote =
        ref.watch(remotePlaybackProvider).value ?? bridge.remoteSession;
    final remoteIndex = remote.itemId == null
        ? -1
        : localSnapshot.queue.items.indexWhere(
            (item) => item.id == remote.itemId,
          );
    final snapshot = capabilities.castConnected
        ? PlaybackSnapshot(
            queue: PlaybackQueue(
              items: localSnapshot.queue.items,
              currentIndex: remoteIndex >= 0
                  ? remoteIndex
                  : localSnapshot.queue.currentIndex,
              shuffle: localSnapshot.queue.shuffle,
              repeatMode: localSnapshot.queue.repeatMode,
            ),
            position: remote.position,
            playing: remote.playing,
            buffering: remote.buffering,
            volume: localSnapshot.volume,
            sleepDeadline: localSnapshot.sleepDeadline,
          )
        : localSnapshot;
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
          if (capabilities.airPlay || capabilities.googleCast)
            IconButton(
              tooltip: capabilities.castConnected
                  ? 'Casting — choose output'
                  : 'Output devices',
              onPressed: () => _showOutputs(snapshot),
              icon: Icon(
                capabilities.castConnected
                    ? Icons.cast_connected_rounded
                    : Icons.speaker_group_rounded,
              ),
            ),
          PopupMenuButton<int>(
            tooltip: snapshot.sleepDeadline == null
                ? 'Sleep timer'
                : 'Sleep timer active',
            icon: Icon(
              snapshot.sleepDeadline == null
                  ? Icons.bedtime_outlined
                  : Icons.bedtime_rounded,
              color: snapshot.sleepDeadline == null
                  ? null
                  : JamColors.accentBright,
            ),
            onSelected: _setSleepTimer,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 15, child: Text('Pause in 15 minutes')),
              PopupMenuItem(value: 30, child: Text('Pause in 30 minutes')),
              PopupMenuItem(value: 60, child: Text('Pause in 1 hour')),
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
            colors: [Color(0xFF1F4A30), JamColors.elevated, JamColors.ink],
            stops: [0, 0.52, 1],
          ),
        ),
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    Expanded(
                      child: _Player(item: item, snapshot: snapshot),
                    ),
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

  Future<void> _setSleepTimer(int minutes) async {
    if (ref.read(platformMediaBridgeProvider).capabilities.castConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Disconnect Cast before setting a timer that pauses this device.',
          ),
        ),
      );
      return;
    }
    await ref
        .read(playbackCoordinatorProvider)
        .setSleepTimer(minutes == 0 ? null : Duration(minutes: minutes));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          minutes == 0
              ? 'Sleep timer canceled'
              : 'Playback will pause in $minutes minutes',
        ),
      ),
    );
  }

  Future<void> _showOutputs(PlaybackSnapshot snapshot) async {
    final bridge = ref.read(platformMediaBridgeProvider);
    final capabilities =
        ref.read(platformCapabilitiesProvider).value ?? bridge.capabilities;
    final targets = ref.read(castTargetsProvider).value ?? const <CastTarget>[];
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Choose an output'),
              subtitle: Text('Available routes are detected at runtime.'),
            ),
            if (capabilities.castConnected)
              ListTile(
                leading: const Icon(Icons.cast_connected_rounded),
                title: const Text('Stop casting'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final coordinator = ref.read(playbackCoordinatorProvider);
                  final position = bridge.remoteSession.position;
                  await bridge.disconnectCast();
                  await coordinator.seek(position);
                  await coordinator.pause();
                },
              ),
            if (capabilities.airPlay)
              ListTile(
                leading: const Icon(Icons.airplay_rounded),
                title: const Text('AirPlay or system output'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await bridge.showOutputPicker();
                },
              ),
            for (final target in targets)
              ListTile(
                leading: const Icon(Icons.cast_rounded),
                title: Text(target.name),
                subtitle: target.model == null ? null : Text(target.model!),
                onTap: () async {
                  final session = ref.read(appControllerProvider).session;
                  if (session == null) return;
                  Navigator.pop(sheetContext);
                  try {
                    await ref.read(playbackCoordinatorProvider).pause();
                    await bridge.connectCastDevice(
                      target.id,
                      session,
                      snapshot,
                      ref.read(jellyfinGatewayProvider),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$error')));
                  }
                },
              ),
            if (!capabilities.airPlay && targets.isEmpty)
              const ListTile(title: Text('No output devices found')),
          ],
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
    final bridge = ref.watch(platformMediaBridgeProvider);
    final casting = bridge.capabilities.castConnected;
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
                tag: 'art-${item.profileId}-${item.id}',
                child: Artwork(item: item, borderRadius: 6, iconSize: 80),
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
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: JamColors.muted),
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
          onSeek: (position) {
            final target = Duration(milliseconds: position.round());
            if (casting) {
              bridge.remoteSeek(target);
            } else {
              coordinator.seek(target);
            }
          },
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
              onPressed: casting
                  ? null
                  : () => coordinator.setShuffle(!snapshot.queue.shuffle),
              color: snapshot.queue.shuffle ? JamColors.accent : null,
              icon: const Icon(Icons.shuffle_rounded),
            ),
            IconButton(
              tooltip: 'Previous',
              iconSize: 38,
              onPressed: casting
                  ? bridge.remotePrevious
                  : coordinator.skipPrevious,
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
                  ? (casting ? bridge.remotePause : coordinator.pause)
                  : (casting ? bridge.remotePlay : coordinator.play),
              icon: Icon(
                snapshot.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Next',
              iconSize: 38,
              onPressed: casting ? bridge.remoteNext : coordinator.skipNext,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            IconButton(
              tooltip: 'Repeat',
              onPressed: casting
                  ? null
                  : () {
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
    final casting = ref
        .watch(platformMediaBridgeProvider)
        .capabilities
        .castConnected;
    final initialIndex = initialTab == 'queue' ? 1 : 0;
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Container(
        margin: EdgeInsets.all(compact ? 0 : 20),
        height: compact ? 410 : null,
        decoration: BoxDecoration(
          color: JamColors.elevated,
          borderRadius: BorderRadius.circular(8),
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
                    AsyncValue(value: final lines?) when lines.isNotEmpty =>
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
                                  lines[index + 1].start! > snapshot.position);
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
                    _ => const Center(child: Text('No lyrics on this server')),
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
                        onTap: casting
                            ? null
                            : () => ref
                                  .read(playbackCoordinatorProvider)
                                  .skipToIndex(index),
                        trailing: casting
                            ? const Tooltip(
                                message:
                                    'Queue editing is unavailable while casting',
                                child: Icon(Icons.cast_connected_rounded),
                              )
                            : PopupMenuButton<String>(
                                tooltip: 'Queue actions',
                                onSelected: (action) {
                                  final coordinator = ref.read(
                                    playbackCoordinatorProvider,
                                  );
                                  switch (action) {
                                    case 'up':
                                      coordinator.moveQueueItem(
                                        index,
                                        index - 1,
                                      );
                                    case 'down':
                                      coordinator.moveQueueItem(
                                        index,
                                        index + 1,
                                      );
                                    case 'remove':
                                      coordinator.removeQueueItemAt(index);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (index > 0)
                                    const PopupMenuItem(
                                      value: 'up',
                                      child: Text('Move up'),
                                    ),
                                  if (index < snapshot.queue.items.length - 1)
                                    const PopupMenuItem(
                                      value: 'down',
                                      child: Text('Move down'),
                                    ),
                                  if (snapshot.queue.items.length > 1)
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Text('Remove from queue'),
                                    ),
                                ],
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
