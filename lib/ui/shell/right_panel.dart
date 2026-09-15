import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/playback_providers.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/state/ui_state.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/follow_button.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/interaction.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/playback_panels.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

/// The desktop right-hand panel: Now Playing, Queue, or Lyrics.
class RightPanel extends StatelessWidget {
  const RightPanel({required this.view, super.key});

  final RightPanelView view;

  @override
  Widget build(BuildContext context) {
    return switch (view) {
      RightPanelView.nowPlaying => const _NowPlayingPanel(),
      RightPanelView.queue => const _PanelFrame(
        title: 'Queue',
        child: QueuePanel(),
      ),
      RightPanelView.lyrics => const _LyricsFrame(),
    };
  }
}

class _PanelFrame extends ConsumerWidget {
  const _PanelFrame({
    required this.title,
    required this.child,
    this.onTitleTap,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: LinkText(
                  title,
                  onTap: onTitleTap,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                iconSize: 20,
                onPressed: () => ref.read(rightPanelProvider.notifier).hide(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _LyricsFrame extends ConsumerWidget {
  const _LyricsFrame();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    return _PanelFrame(
      title: 'Lyrics',
      child: track == null
          ? const Center(
              child: Text(
                'Play something to see its lyrics.',
                style: TextStyle(color: JamColors.muted),
              ),
            )
          : LyricsPanel(
              key: ValueKey(track.id),
              item: track,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            ),
    );
  }
}

class _NowPlayingPanel extends ConsumerWidget {
  const _NowPlayingPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) {
      return const _PanelFrame(
        title: 'Now playing',
        child: Center(
          child: Text(
            'Play something to see it here.',
            style: TextStyle(color: JamColors.muted),
          ),
        ),
      );
    }
    final index = ref.watch(libraryIndexProvider);
    final artist = track.artistId == null ? null : index.byId[track.artistId];
    final moreFromAlbum = (index.tracksByAlbum[track.albumId] ?? const [])
        .where((candidate) => candidate.id != track.id)
        .take(5)
        .toList(growable: false);
    return _PanelFrame(
      title: track.albumName ?? 'Now playing',
      onTitleTap: track.albumId == null ? null : () => openItem(context, track),
      child: EntranceMotion(
        watchKey: track.id,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Artwork(item: track, borderRadius: 8, iconSize: 72),
            ),
            const SizedBox(height: 16),
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
                        style: const TextStyle(
                          color: JamColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ItemMenuButton(item: track, size: 20),
                LikeButton(item: track, size: 22),
              ],
            ),
            if (artist != null) ...[
              const SizedBox(height: 24),
              _ArtistCard(artist: artist),
            ],
            const _NextInQueueCard(),
            if (moreFromAlbum.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Card(
                title: 'More from this album',
                child: Column(
                  children: [
                    for (final candidate in moreFromAlbum)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          candidate.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          candidate.artistLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => ref
                            .read(appControllerProvider.notifier)
                            .play(candidate),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      decoration: BoxDecoration(
        color: JamColors.soft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist});

  final LibraryItem artist;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JamColors.soft,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openItem(context, artist),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Artwork(item: artist, borderRadius: 0, iconSize: 56),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'About the artist',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FollowButton(item: artist),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextInQueueCard extends ConsumerWidget {
  const _NextInQueueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(
      playbackQueueProvider.select((queue) {
        final upNext = queue.upNextIndices;
        return upNext.isEmpty
            ? null
            : (queue.items[upNext.first], upNext.first);
      }),
    );
    if (next == null) return const SizedBox.shrink();
    final (item, index) = next;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _Card(
        title: 'Next in queue',
        action: TextButton(
          onPressed: () =>
              ref.read(rightPanelProvider.notifier).show(RightPanelView.queue),
          child: const Text('Open queue'),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox.square(
            dimension: 44,
            child: Artwork(item: item, borderRadius: 4, iconSize: 18),
          ),
          title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            item.artistLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => ref.read(playerControllerProvider).skipToIndex(index),
        ),
      ),
    );
  }
}
