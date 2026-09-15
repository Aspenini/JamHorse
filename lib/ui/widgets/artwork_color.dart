import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/core/artwork_cache.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

/// A dark, saturated tint taken from artwork, like Spotify's page headers.
/// Resolves to null when the image cannot be loaded.
final artworkColorProvider = FutureProvider.family<Color?, Uri>((
  ref,
  imageUrl,
) async {
  final session = ref.watch(sessionProvider);
  if (session == null || !isSessionImage(session, imageUrl)) return null;
  // The smallest thumbnail bucket is plenty for color quantization and is
  // usually already cached by list rows.
  final small = sizedImageUrl(imageUrl, 160);
  try {
    final scheme = await ColorScheme.fromImageProvider(
      provider: CachedNetworkImageProvider(
        small.toString(),
        cacheKey: '${session.profile.profileId}:$small',
        headers: ref.read(jellyfinGatewayProvider).playbackHeaders(session),
        cacheManager: ArtworkCache.manager,
      ),
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return Color.lerp(scheme.primaryContainer, Colors.black, 0.2);
  } catch (error) {
    appLog.fine('Artwork color unavailable: $error');
    return null;
  }
});

extension ArtworkColorRef on WidgetRef {
  /// [item]'s artwork tint, or [fallback] until (or unless) it resolves.
  Color artworkColor(
    LibraryItem? item, {
    Color fallback = const Color(0xFF404040),
  }) {
    final url = item?.imageUrl;
    if (url == null) return fallback;
    return watch(artworkColorProvider(url)).value ?? fallback;
  }
}
