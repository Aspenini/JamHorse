import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/artwork_color.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/output_picker.dart';
import 'package:jamhorse/ui/widgets/playback_panels.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

/// Spotify's full-screen phone player, tinted by the artwork, with a lyrics
/// card below the controls and the queue in a sheet.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key, this.initialTab = 'player'});

  /// `queue` opens the queue sheet on arrival.
  final String initialTab;

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTab == 'queue') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showQueue();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Choose something to play.')),
      );
    }
    final tint = ref.artworkColor(track, fallback: const Color(0xFF1F4A30));
    final sleepDeadline = ref.watch(sleepDeadlineProvider);
    final bridge = ref.watch(platformMediaBridgeProvider);
    final capabilities =
        ref.watch(platformCapabilitiesProvider).value ?? bridge.capabilities;
    final casting = capabilities.castConnected;
    return Scaffold(
      backgroundColor: JamColors.ink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Close',
          iconSize: 32,
          color: Colors.white,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PLAYING FROM ALBUM',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            Text(
              track.albumName ?? 'Your queue',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            tooltip: sleepDeadline == null ? 'Sleep timer' : 'Sleep timer on',
            icon: Icon(
              sleepDeadline == null
                  ? Icons.bedtime_outlined
                  : Icons.bedtime_rounded,
              color: sleepDeadline == null ? null : JamColors.accentBright,
            ),
            onSelected: _setSleepTimer,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 15, child: Text('Pause in 15 minutes')),
              PopupMenuItem(value: 30, child: Text('Pause in 30 minutes')),
              PopupMenuItem(value: 60, child: Text('Pause in 1 hour')),
              PopupMenuItem(value: 0, child: Text('Turn off sleep timer')),
            ],
          ),
          ItemMenuButton(item: track),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tint,
              Color.lerp(tint, JamColors.ink, 0.65)!,
              JamColors.ink,
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 40,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Artwork(
                        item: track,
                        borderRadius: 8,
                        iconSize: 80,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinkText(
                          track.name,
                          onTap: () => openItem(context, track),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        LinkText(
                          track.artistLine,
                          onTap: track.artistId == null
                              ? null
                              : () => openArtist(context, track),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  LikeButton(item: track, size: 28),
                ],
              ),
              const SizedBox(height: 12),
              const PlaybackSeekBar(layout: SeekBarLayout.stacked),
              const SizedBox(height: 4),
              const TransportControls(large: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (capabilities.googleCast || capabilities.airPlay)
                    IconButton(
                      tooltip: casting ? 'Casting' : 'Connect to a device',
                      color: casting ? JamColors.accentBright : Colors.white70,
                      onPressed: () => showOutputPicker(context, ref),
                      icon: Icon(
                        casting
                            ? Icons.cast_connected_rounded
                            : Icons.speaker_group_outlined,
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Queue',
                    color: Colors.white70,
                    onPressed: _showQueue,
                    icon: const Icon(Icons.queue_music_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: 380,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Color.lerp(tint, Colors.black, 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        'Lyrics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: LyricsPanel(
                        key: ValueKey(track.id),
                        item: track,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQueue() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: JamColors.elevated,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Queue',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Expanded(child: QueuePanel()),
          ],
        ),
      ),
    );
  }

  Future<void> _setSleepTimer(int minutes) async {
    final messenger = ScaffoldMessenger.of(context);
    if (ref.read(castConnectedProvider)) {
      messenger.showSnackBar(
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          minutes == 0
              ? 'Sleep timer turned off'
              : 'Playback will pause in $minutes minutes',
        ),
      ),
    );
  }
}
