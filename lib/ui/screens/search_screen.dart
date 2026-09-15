import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/media_row.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';
import 'package:jamhorse/ui/widgets/user_avatar.dart';

enum _SearchFilter {
  all('All'),
  songs('Songs'),
  artists('Artists'),
  albums('Albums'),
  playlists('Playlists');

  const _SearchFilter(this.label);

  final String label;
}

/// "Browse all" genre tiles when idle; grouped results (top result, songs,
/// artists, albums, playlists) while searching.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );
  var _filter = _SearchFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktopLayout(context);
    final query = ref.watch(searchQueryProvider).trim();
    return Scaffold(
      backgroundColor: desktop ? Colors.transparent : JamColors.ink,
      body: CustomScrollView(
        slivers: [
          if (!desktop) ...[
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const ProfileButton(),
                      const SizedBox(width: 12),
                      Text(
                        'Search',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              primary: false,
              backgroundColor: JamColors.ink,
              toolbarHeight: 64,
              titleSpacing: 16,
              title: _MobileSearchField(controller: _controller),
            ),
          ],
          if (query.isEmpty)
            ..._browseAll(desktop)
          else
            ..._results(query, desktop),
        ],
      ),
    );
  }

  List<Widget> _browseAll(bool desktop) {
    final genres = ref.watch(libraryIndexProvider.select((i) => i.genres));
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, desktop ? 24 : 8, 16, 12),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Browse all',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        sliver: genres.isEmpty
            ? const SliverToBoxAdapter(
                child: Text(
                  'Genres from your library will show up here.',
                  style: TextStyle(color: JamColors.muted),
                ),
              )
            : SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: desktop ? 240 : 220,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: desktop ? 1 : 1.7,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) =>
                    _GenreTile(genre: genres[index]),
              ),
      ),
    ];
  }

  List<Widget> _results(String query, bool desktop) {
    final results = ref.watch(
      appControllerProvider.select((state) => state.searchResults),
    );
    final controller = ref.read(appControllerProvider.notifier);
    List<LibraryItem> ofType(LibraryItemType type) =>
        results.where((item) => item.type == type).toList(growable: false);
    final tracks = ofType(LibraryItemType.track);
    final artists = ofType(LibraryItemType.artist);
    final albums = ofType(LibraryItemType.album);
    final playlists = ofType(LibraryItemType.playlist);
    void playTrack(LibraryItem track) =>
        controller.playQueue(tracks, startWith: track);

    final chips = SliverToBoxAdapter(
      child: SizedBox(
        height: 52,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          children: [
            for (final filter in _SearchFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter.label),
                  selected: _filter == filter,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              ),
          ],
        ),
      ),
    );
    if (results.isEmpty) {
      return [
        chips,
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No results found for "$query"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check the spelling, or try fewer keywords.',
                  style: TextStyle(color: JamColors.muted),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    Widget trackList(List<LibraryItem> list) => SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: desktop ? 8 : 0),
      sliver: SliverList.builder(
        itemCount: list.length,
        itemBuilder: (context, index) => desktop
            ? TrackRow(
                index: index + 1,
                track: list[index],
                showAlbum: false,
                onTap: () => playTrack(list[index]),
              )
            : MobileTrackTile(
                track: list[index],
                onTap: () => playTrack(list[index]),
              ),
      ),
    );

    Widget grid(List<LibraryItem> list) => SliverPadding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 40),
      sliver: SliverArtworkGrid(items: list),
    );

    return [
      chips,
      ...switch (_filter) {
        _SearchFilter.songs => [trackList(tracks)],
        _SearchFilter.artists => [grid(artists)],
        _SearchFilter.albums => [grid(albums)],
        _SearchFilter.playlists => [grid(playlists)],
        _SearchFilter.all => [
          if (_topResult(query, results) case final top?)
            desktop
                ? SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _Section(
                              title: 'Top result',
                              child: _TopResultCard(item: top),
                            ),
                          ),
                          if (tracks.isNotEmpty) ...[
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _Section(
                                title: 'Songs',
                                child: Column(
                                  children: [
                                    for (final (i, track)
                                        in tracks.take(4).indexed)
                                      TrackRow(
                                        index: i + 1,
                                        track: track,
                                        showAlbum: false,
                                        onTap: () => playTrack(track),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : SliverList.list(
                    children: [
                      _TopResultTile(item: top),
                      for (final track in tracks.take(4))
                        MobileTrackTile(
                          track: track,
                          onTap: () => playTrack(track),
                        ),
                    ],
                  ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 40),
            sliver: SliverList.list(
              children: [
                MediaRow(title: 'Artists', items: artists),
                MediaRow(title: 'Albums', items: albums),
                MediaRow(title: 'Playlists', items: playlists),
              ],
            ),
          ),
        ],
      },
    ];
  }

  /// An exact name match wins (artists first), then the first artist whose
  /// name starts with the query, then the server's own ranking.
  static LibraryItem? _topResult(String query, List<LibraryItem> results) {
    final needle = query.toLowerCase();
    const priority = [
      LibraryItemType.artist,
      LibraryItemType.album,
      LibraryItemType.playlist,
      LibraryItemType.track,
    ];
    for (final type in priority) {
      final exact = results.firstWhereOrNull(
        (item) => item.type == type && item.name.toLowerCase() == needle,
      );
      if (exact != null) return exact;
    }
    return results.firstWhereOrNull(
          (item) =>
              item.type == LibraryItemType.artist &&
              item.name.toLowerCase().startsWith(needle),
        ) ??
        results.firstOrNull;
  }
}

class _MobileSearchField extends ConsumerWidget {
  const _MobileSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    const hint = Color(0xFF535353);
    return TextField(
      controller: controller,
      onChanged: ref.read(searchQueryProvider.notifier).set,
      textInputAction: TextInputAction.search,
      cursorColor: Colors.black,
      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'What do you want to listen to?',
        hintStyle: const TextStyle(color: hint, fontWeight: FontWeight.w600),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.black),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                color: Colors.black,
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).set('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        child,
      ],
    );
  }
}

class _TopResultCard extends ConsumerWidget {
  const _TopResultCard({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = item.type == LibraryItemType.artist;
    final controller = ref.read(appControllerProvider.notifier);
    return Hoverable(
      semanticLabel: '${item.name}, ${itemTypeLabel(item.type)}',
      onTap: () => item.type == LibraryItemType.track
          ? controller.play(item)
          : openItem(context, item),
      onLongPress: () => showItemMenu(context, ref, item),
      onSecondaryTapUp: (details) =>
          showItemMenu(context, ref, item, position: details.globalPosition),
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hovered ? const Color(0xFF282828) : const Color(0xFF181818),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 92,
                  child: Artwork(
                    item: item,
                    borderRadius: artist ? 46 : 4,
                    iconSize: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (!artist)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            item.artistLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: JamColors.muted),
                          ),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: JamColors.ink.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          itemTypeLabel(item.type),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: PlayOverlayButton(
                visible: hovered,
                onPressed: () => controller.play(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopResultTile extends ConsumerWidget {
  const _TopResultTile({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = item.type == LibraryItemType.artist;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox.square(
        dimension: 56,
        child: Artwork(item: item, borderRadius: artist ? 28 : 4, iconSize: 22),
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        artist ? 'Artist' : '${itemTypeLabel(item.type)} • ${item.artistLine}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => item.type == LibraryItemType.track
          ? ref.read(appControllerProvider.notifier).play(item)
          : openItem(context, item),
      onLongPress: () => showItemMenu(context, ref, item),
    );
  }
}

class _GenreTile extends StatelessWidget {
  const _GenreTile({required this.genre});

  final LibraryItem genre;

  static const _colors = [
    Color(0xFFDC148C),
    Color(0xFF006450),
    Color(0xFF8400E7),
    Color(0xFF1E3264),
    Color(0xFFE8115B),
    Color(0xFF477D95),
    Color(0xFFBA5D07),
    Color(0xFF148A08),
    Color(0xFF503750),
    Color(0xFFE91429),
    Color(0xFF7358FF),
    Color(0xFF27856A),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[genre.name.hashCode.abs() % _colors.length];
    return Hoverable(
      semanticLabel: genre.name,
      hoverScale: 1.02,
      onTap: () => openItem(context, genre),
      builder: (context, hovered) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: color,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    genre.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -14,
                bottom: -6,
                child: Transform.rotate(
                  angle: 0.44,
                  child: SizedBox.square(
                    dimension: 84,
                    child: Artwork(item: genre, borderRadius: 4, iconSize: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
