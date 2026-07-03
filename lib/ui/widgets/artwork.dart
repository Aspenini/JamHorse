import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/artwork_cache.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';

class Artwork extends ConsumerWidget {
  const Artwork({
    required this.item,
    super.key,
    this.borderRadius = 16,
    this.iconSize = 42,
  });

  final LibraryItem item;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appControllerProvider).session;
    final placeholder = _ArtworkPlaceholder(
      icon: switch (item.type) {
        LibraryItemType.artist => Icons.person_rounded,
        LibraryItemType.playlist => Icons.queue_music_rounded,
        LibraryItemType.genre => Icons.graphic_eq_rounded,
        _ => Icons.album_rounded,
      },
      iconSize: iconSize,
      seed: item.name.hashCode,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: item.imageUrl == null
          ? placeholder
          : CachedNetworkImage(
              cacheManager: ArtworkCache.manager,
              imageUrl: item.imageUrl.toString(),
              httpHeaders: session == null
                  ? const {}
                  : ref
                        .read(jellyfinGatewayProvider)
                        .playbackHeaders(session),
              fit: BoxFit.cover,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
              fadeInDuration: const Duration(milliseconds: 220),
            ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder({
    required this.icon,
    required this.iconSize,
    required this.seed,
  });

  final IconData icon;
  final double iconSize;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final options = [
      const [Color(0xFF5630A8), Color(0xFF29184F)],
      const [Color(0xFFB94357), Color(0xFF4A1721)],
      const [Color(0xFF187C78), Color(0xFF0D393B)],
      const [Color(0xFFB66C24), Color(0xFF4F2D13)],
    ];
    final colors = options[seed.abs() % options.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: Colors.white70),
      ),
    );
  }
}

class ArtworkCard extends ConsumerWidget {
  const ArtworkCard({
    required this.item,
    required this.onTap,
    super.key,
    this.width = 176,
  });

  final LibraryItem item;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: '${item.name}, ${item.subtitle ?? item.type.name}',
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: () => _showActions(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Hero(
                    tag: 'art-${item.serverId}-${item.id}',
                    child: Artwork(item: item),
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle ?? item.type.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: JamColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                ref.read(appControllerProvider.notifier).play(item);
              },
            ),
            ListTile(
              leading: Icon(
                item.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              title: Text(
                item.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(appControllerProvider.notifier).toggleFavorite(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                ref.read(appControllerProvider.notifier).download(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}
