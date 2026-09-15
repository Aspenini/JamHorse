import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/artwork_cache.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';

/// [url] with Jellyfin's `maxWidth` set to [width] pixels.
Uri sizedImageUrl(Uri url, int width) {
  return url.replace(
    queryParameters: {...url.queryParameters, 'maxWidth': '$width'},
  );
}

/// Whether [url] is served by the session's own server, the only origin
/// that may receive its auth headers.
bool isSessionImage(AuthSession? session, Uri? url) {
  if (session == null || url == null) return false;
  final base = session.profile.baseUrl;
  return base.scheme == url.scheme &&
      base.host == url.host &&
      base.port == url.port;
}

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
    final session = ref.watch(sessionProvider);
    final image = item.imageUrl;
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
    final Widget child;
    if (session == null ||
        image == null ||
        session.profile.profileId != item.profileId ||
        !isSessionImage(session, image)) {
      child = placeholder;
    } else {
      child = LayoutBuilder(
        builder: (context, constraints) {
          final extent = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 300.0;
          final pixels = extent * MediaQuery.devicePixelRatioOf(context);
          // A few size buckets keep thumbnails small while letting every view
          // of the same size share one cached file.
          final width = pixels <= 160
              ? 160
              : pixels <= 400
              ? 400
              : 800;
          final url = sizedImageUrl(image, width);
          return CachedNetworkImage(
            cacheManager: ArtworkCache.manager,
            cacheKey: '${item.profileId}:$url',
            imageUrl: url.toString(),
            httpHeaders: ref
                .read(jellyfinGatewayProvider)
                .playbackHeaders(session),
            memCacheWidth: width,
            fit: BoxFit.cover,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
            fadeInDuration: const Duration(milliseconds: 220),
          );
        },
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
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

  static const _palettes = [
    [Color(0xFF5630A8), Color(0xFF29184F)],
    [Color(0xFFB94357), Color(0xFF4A1721)],
    [Color(0xFF187C78), Color(0xFF0D393B)],
    [Color(0xFFB66C24), Color(0xFF4F2D13)],
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _palettes[seed.abs() % _palettes.length],
        ),
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: Colors.white70),
      ),
    );
  }
}

/// Spotify's Liked Songs cover: a purple-to-mint gradient with a heart.
class LikedSongsArt extends StatelessWidget {
  const LikedSongsArt({super.key, this.iconSize = 48, this.borderRadius = 0});

  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Cover for the pinned Downloads collection.
class DownloadsArt extends StatelessWidget {
  const DownloadsArt({super.key, this.iconSize = 48, this.borderRadius = 0});

  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF076653),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.download_for_offline_rounded,
          color: JamColors.accent,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Square (or round, for artists) media card with a hover play button.
/// Without explicit callbacks, tapping opens the item and play plays it.
class ArtworkCard extends ConsumerWidget {
  const ArtworkCard({
    required this.item,
    super.key,
    this.onTap,
    this.onPlay,
    this.subtitle,
    this.width = 176,
  });

  /// Grid rows and horizontal lists reserve this much height beyond the
  /// card width for padding, title, and a two-line subtitle.
  static const extraHeight = 84.0;

  final LibraryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final String? subtitle;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circular = item.type == LibraryItemType.artist;
    final controller = ref.read(appControllerProvider.notifier);
    final label = subtitle ?? itemSubtitle(item);
    return SizedBox(
      width: width,
      child: Hoverable(
        semanticLabel: '${item.name}, $label',
        hoverScale: 1.01,
        onTap:
            onTap ??
            () => item.type == LibraryItemType.track
                ? controller.play(item)
                : openItem(context, item),
        onLongPress: () => showItemMenu(context, ref, item),
        onSecondaryTapUp: (details) =>
            showItemMenu(context, ref, item, position: details.globalPosition),
        builder: (context, hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovered ? JamColors.softHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Artwork(item: item, borderRadius: circular ? 999 : 6),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: PlayOverlayButton(
                        visible: hovered,
                        onPressed: onPlay ?? () => controller.play(item),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                label,
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
    );
  }
}
