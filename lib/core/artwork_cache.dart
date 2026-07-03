import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for album/artist artwork. Generous limits and a long stale
/// period so a synced library keeps rendering instantly — including fully
/// offline — instead of refetching from the server.
class ArtworkCache {
  const ArtworkCache._();

  static const key = 'jamhorseArtwork';

  static final manager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 5000,
    ),
  );

  static Future<void> clear() => manager.emptyCache();
}
