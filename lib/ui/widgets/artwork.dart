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
    final authenticated =
        session != null &&
        session.profile.profileId == item.profileId &&
        item.imageUrl != null &&
        _sameOrigin(session.profile.baseUrl, item.imageUrl!);
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
      child: item.imageUrl == null || !authenticated
          ? placeholder
          : CachedNetworkImage(
              cacheManager: ArtworkCache.manager,
              cacheKey: '${item.profileId}:${item.imageUrl}',
              imageUrl: item.imageUrl.toString(),
              httpHeaders: ref
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

class ArtworkCard extends ConsumerStatefulWidget {
  const ArtworkCard({
    required this.item,
    required this.onTap,
    super.key,
    this.onPlay,
    this.width = 176,
  });

  final LibraryItem item;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final double width;

  @override
  ConsumerState<ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends ConsumerState<ArtworkCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Semantics(
        button: true,
        label:
            '${widget.item.name}, '
            '${widget.item.subtitle ?? widget.item.type.name}',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: AnimatedScale(
            scale: _pressed
                ? 0.985
                : _hovered
                ? 1.012
                : 1,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onLongPress: () => _showActions(context, ref),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hovered ? JamColors.softHover : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _hovered
                      ? const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : const [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedScale(
                            scale: _hovered ? 1.018 : 1,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            child: Hero(
                              tag:
                                  'art-${widget.item.profileId}-${widget.item.id}',
                              child: Artwork(
                                item: widget.item,
                                borderRadius:
                                    widget.item.type == LibraryItemType.artist
                                    ? 999
                                    : 6,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 9,
                            bottom: 9,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 190),
                              curve: Curves.easeOutCubic,
                              offset: _hovered
                                  ? Offset.zero
                                  : const Offset(0, 0.35),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: _hovered ? 1 : 0,
                                child: Material(
                                  color: JamColors.accent,
                                  elevation: 8,
                                  shadowColor: Colors.black87,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: widget.onPlay ?? widget.onTap,
                                    child: const SizedBox.square(
                                      dimension: 48,
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _hovered
                                ? Colors.white
                                : const Color(0xFFF2F2F2),
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(),
                      child: Text(
                        widget.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.item.subtitle ?? widget.item.type.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: JamColors.muted),
                    ),
                  ],
                ),
              ),
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
                ref.read(appControllerProvider.notifier).play(widget.item);
              },
            ),
            ListTile(
              leading: Icon(
                widget.item.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              title: Text(
                widget.item.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
              ),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(appControllerProvider.notifier)
                    .toggleFavorite(widget.item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                ref.read(appControllerProvider.notifier).download(widget.item);
              },
            ),
          ],
        ),
      ),
    );
  }
}

bool _sameOrigin(Uri left, Uri right) {
  return left.scheme == right.scheme &&
      left.host == right.host &&
      left.port == right.port;
}
