import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';

/// Spotify's outlined Follow / Following toggle for artists, backed by
/// Jellyfin favorites.
class FollowButton extends ConsumerWidget {
  const FollowButton({required this.item, super.key});

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(
      libraryIndexProvider.select(
        (index) => index.byId[item.id]?.isFavorite ?? item.isFavorite,
      ),
    );
    return OutlinedButton(
      onPressed: () => ref
          .read(appControllerProvider.notifier)
          .toggleFavorite(item.copyWith(isFavorite: following)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: following ? Colors.white : JamColors.subtle),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Text(following ? 'Following' : 'Follow'),
    );
  }
}
