import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/core/artwork_cache.dart';
import 'package:jamhorse/state/providers.dart';

class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(
      appControllerProvider.select((state) => state.session),
    );
    if (session == null) {
      return _AvatarFallback(size: size, label: '?');
    }

    final gateway = ref.read(jellyfinGatewayProvider);
    final imageUri = gateway.userImageUri(
      session,
      width: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    );
    return Semantics(
      image: true,
      label: '${session.profile.username} profile picture',
      child: ClipOval(
        child: CachedNetworkImage(
          cacheManager: ArtworkCache.manager,
          cacheKey:
              '${session.profile.profileId}:user-avatar:'
              '${session.profile.userId}',
          imageUrl: imageUri.toString(),
          httpHeaders: gateway.playbackHeaders(session),
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (_, _) =>
              _AvatarFallback(size: size, label: session.profile.username),
          errorWidget: (_, _, _) =>
              _AvatarFallback(size: size, label: session.profile.username),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size, required this.label});

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return ColoredBox(
      color: const Color(0xFF3A3A3A),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
