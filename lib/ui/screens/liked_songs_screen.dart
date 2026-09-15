import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/format.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/detail_page.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

enum _LikedSort {
  title('Title'),
  artist('Artist'),
  album('Album');

  const _LikedSort(this.label);

  final String label;
}

class LikedSongsScreen extends ConsumerStatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  ConsumerState<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends ConsumerState<LikedSongsScreen> {
  var _query = '';
  var _searching = false;
  var _sort = _LikedSort.title;

  List<LibraryItem> _visible(List<LibraryItem> liked) {
    final needle = _query.trim().toLowerCase();
    final visible = needle.isEmpty
        ? liked.toList()
        : liked
              .where(
                (track) =>
                    '${track.name} ${track.artistLine} '
                            '${track.albumName ?? ''}'
                        .toLowerCase()
                        .contains(needle),
              )
              .toList();
    String key(LibraryItem track) => switch (_sort) {
      _LikedSort.title => track.name,
      _LikedSort.artist => track.artistLine,
      _LikedSort.album => track.albumName ?? '',
    }.toLowerCase();
    mergeSort<LibraryItem>(
      visible,
      compare: (a, b) => key(a).compareTo(key(b)),
    );
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopLayout(context);
    final liked = ref.watch(libraryIndexProvider.select((i) => i.likedTracks));
    final visible = _visible(liked);
    final likedIds = {for (final track in liked) track.id};
    final controller = ref.read(appControllerProvider.notifier);
    final username = ref.watch(
      sessionProvider.select((session) => session?.profile.username ?? 'You'),
    );
    final total = liked.fold(Duration.zero, (sum, t) => sum + t.duration);

    return DetailPage(
      title: 'Liked Songs',
      typeLabel: 'Playlist',
      tint: const Color(0xFF5038A0),
      artwork: const LikedSongsArt(iconSize: 80, borderRadius: 4),
      metadata: Text(
        '$username • ${liked.length} songs'
        '${liked.isEmpty ? '' : ', ${formatTotalDuration(total)}'}',
        style: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: DetailActionRow(
        play: ContextPlayButton(
          enabled: liked.isNotEmpty,
          isPlayingFrom: (current) => likedIds.contains(current.id),
          onPlay: () => controller.playQueue(visible),
        ),
        shuffle: IconButton(
          tooltip: 'Shuffle play',
          iconSize: desktop ? 30 : 26,
          color: JamColors.muted,
          onPressed: liked.isEmpty
              ? null
              : () => controller.playQueue(visible, shuffle: true),
          icon: const Icon(Icons.shuffle_rounded),
        ),
        utilities: [
          IconButton(
            tooltip: 'Download all',
            iconSize: desktop ? 30 : 24,
            color: JamColors.muted,
            onPressed: liked.isEmpty
                ? null
                : () {
                    controller.downloadAll(liked);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${liked.length} songs'),
                      ),
                    );
                  },
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
        ],
        trailing: [if (desktop) _filterControls(desktop: true)],
      ),
      slivers: [
        if (!desktop)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverToBoxAdapter(child: _filterControls(desktop: false)),
          ),
        if (liked.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'Songs you like will appear here.\n'
                'Tap the heart on any song; likes sync with Jellyfin favorites.',
                textAlign: TextAlign.center,
                style: TextStyle(color: JamColors.muted),
              ),
            ),
          )
        else if (desktop) ...[
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverToBoxAdapter(child: TrackTableHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) => TrackRow(
                index: index + 1,
                track: visible[index],
                onTap: () =>
                    controller.playQueue(visible, startWith: visible[index]),
              ),
            ),
          ),
        ] else
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) => MobileTrackTile(
              track: visible[index],
              trailing: LikeButton(item: visible[index]),
              onTap: () =>
                  controller.playQueue(visible, startWith: visible[index]),
            ),
          ),
      ],
    );
  }

  Widget _filterControls({required bool desktop}) {
    final field = TextField(
      autofocus: true,
      style: const TextStyle(fontSize: 14),
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search in Liked Songs',
        hintStyle: const TextStyle(fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: IconButton(
          tooltip: 'Close search',
          iconSize: 18,
          onPressed: () => setState(() {
            _query = '';
            _searching = false;
          }),
          icon: const Icon(Icons.close_rounded),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
      ),
    );
    final sort = PopupMenuButton<_LikedSort>(
      tooltip: 'Sort by',
      initialValue: _sort,
      onSelected: (value) => setState(() => _sort = value),
      itemBuilder: (context) => [
        for (final option in _LikedSort.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == _sort,
            child: Text(option.label),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sort.label,
              style: const TextStyle(
                color: JamColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.swap_vert_rounded,
              size: 18,
              color: JamColors.muted,
            ),
          ],
        ),
      ),
    );
    final searchButton = IconButton(
      tooltip: 'Search in Liked Songs',
      color: JamColors.muted,
      onPressed: () => setState(() => _searching = true),
      icon: const Icon(Icons.search_rounded),
    );
    if (desktop) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_searching) SizedBox(width: 240, child: field) else searchButton,
          sort,
        ],
      );
    }
    return Row(
      children: [
        if (_searching)
          Expanded(child: field)
        else ...[
          searchButton,
          const Spacer(),
        ],
        sort,
      ],
    );
  }
}
