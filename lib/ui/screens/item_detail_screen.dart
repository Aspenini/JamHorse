import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/core/format.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/artwork_color.dart';
import 'package:jamhorse/ui/widgets/detail_page.dart';
import 'package:jamhorse/ui/widgets/follow_button.dart';
import 'package:jamhorse/ui/widgets/hoverable.dart';
import 'package:jamhorse/ui/widgets/item_menu.dart';
import 'package:jamhorse/ui/widgets/media_row.dart';
import 'package:jamhorse/ui/widgets/track_table.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key, this.fallback});

  final String itemId;

  /// Used when the item is not in the synced library, e.g. a fresh search
  /// result.
  final LibraryItem? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item =
        ref.watch(libraryIndexProvider.select((index) => index.byId[itemId])) ??
        fallback;
    if (item == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('This item is no longer in your library.')),
      );
    }
    return switch (item.type) {
      LibraryItemType.artist => _ArtistPage(artist: item),
      LibraryItemType.genre => _GenrePage(genre: item),
      _ => _TrackListPage(item: item),
    };
  }
}

const _metadataStyle = TextStyle(
  color: Color(0xFFE0E0E0),
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

Widget _shuffleButton(VoidCallback? onPressed, bool desktop) {
  return IconButton(
    tooltip: 'Shuffle play',
    iconSize: desktop ? 30 : 26,
    color: JamColors.muted,
    onPressed: onPressed,
    icon: const Icon(Icons.shuffle_rounded),
  );
}

/// Albums, playlists, and folders: a track table.
class _TrackListPage extends ConsumerWidget {
  const _TrackListPage({required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktopLayout(context);
    final album = item.type == LibraryItemType.album;
    final local = album
        ? ref.watch(
            libraryIndexProvider.select(
              (index) => index.tracksByAlbum[item.id],
            ),
          )
        : null;
    final useLocal = local != null && local.isNotEmpty;
    final key = (item.id, item.type);
    final remote = useLocal ? null : ref.watch(itemChildrenProvider(key));
    final tracks = useLocal ? local : remote?.value ?? const <LibraryItem>[];
    final ids = {for (final track in tracks) track.id};
    final controller = ref.read(appControllerProvider.notifier);
    final total = tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final username = ref.watch(
      sessionProvider.select((session) => session?.profile.username),
    );
    final downloadedCount = ref.watch(
      downloadedItemIdsProvider.select(
        (downloaded) => ids.where(downloaded.contains).length,
      ),
    );
    final allDownloaded = tracks.isNotEmpty && downloadedCount == tracks.length;
    final summary = tracks.isEmpty
        ? null
        : '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}, '
              '${formatTotalDuration(total)}';

    final metadata = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (album)
          LinkText(
            item.subtitle?.isNotEmpty ?? false
                ? item.subtitle!
                : 'Unknown artist',
            onTap: item.artistId == null
                ? null
                : () => openArtist(context, item),
            style: _metadataStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          )
        else if (username != null)
          Text(
            username,
            style: _metadataStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        Text(
          [
            // Continues the artist or owner name shown before it.
            if (album || username != null) '',
            if (album && item.productionYear != null) '${item.productionYear}',
            ?summary,
          ].join(' • '),
          style: _metadataStyle,
        ),
      ],
    );

    final List<Widget> content;
    if (remote != null && remote.isLoading && tracks.isEmpty) {
      content = const [
        SliverPadding(
          padding: EdgeInsets.all(40),
          sliver: SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ];
    } else if (remote != null && remote.hasError && tracks.isEmpty) {
      content = [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  "Couldn't load this ${itemTypeLabel(item.type).toLowerCase()}.",
                ),
                TextButton(
                  onPressed: () => ref.invalidate(itemChildrenProvider(key)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ];
    } else if (tracks.isEmpty) {
      content = [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                album
                    ? 'No songs in this album yet.'
                    : 'Add songs from any page with the "…" menu.',
                style: const TextStyle(color: JamColors.muted),
              ),
            ),
          ),
        ),
      ];
    } else if (desktop) {
      content = [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverToBoxAdapter(
            child: TrackTableHeader(showAlbum: !album),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          sliver: SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return TrackRow(
                index: album ? track.indexNumber ?? index + 1 : index + 1,
                track: track,
                showAlbum: !album,
                showArtwork: !album,
                onTap: () => controller.playQueue(tracks, startWith: track),
              );
            },
          ),
        ),
      ];
    } else {
      content = [
        SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) => MobileTrackTile(
            track: tracks[index],
            showArtwork: !album,
            onTap: () => controller.playQueue(tracks, startWith: tracks[index]),
          ),
        ),
      ];
    }

    return DetailPage(
      title: item.name,
      typeLabel: itemTypeLabel(item.type),
      tint: ref.artworkColor(item),
      artwork: Artwork(item: item, borderRadius: 4, iconSize: 64),
      metadata: metadata,
      appBarActions: [ItemMenuButton(item: item)],
      actions: DetailActionRow(
        play: ContextPlayButton(
          enabled: tracks.isNotEmpty,
          isPlayingFrom: (current) => ids.contains(current.id),
          onPlay: () => controller.playQueue(tracks),
        ),
        shuffle: _shuffleButton(
          tracks.isEmpty
              ? null
              : () => controller.playQueue(tracks, shuffle: true),
          desktop,
        ),
        utilities: [
          LikeButton(item: item, size: desktop ? 30 : 24),
          IconButton(
            tooltip: allDownloaded ? 'Downloaded' : 'Download',
            iconSize: desktop ? 30 : 24,
            color: allDownloaded ? JamColors.accentBright : JamColors.muted,
            onPressed: allDownloaded || tracks.isEmpty
                ? null
                : () {
                    controller.downloadAll(tracks);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading ${item.name}')),
                    );
                  },
            icon: Icon(
              allDownloaded
                  ? Icons.download_for_offline_rounded
                  : Icons.download_for_offline_outlined,
            ),
          ),
          if (desktop) ItemMenuButton(item: item, size: 28),
        ],
      ),
      slivers: content,
    );
  }
}

class _ArtistPage extends ConsumerWidget {
  const _ArtistPage({required this.artist});

  final LibraryItem artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktopLayout(context);
    final remoteAlbums = ref.watch(
      itemChildrenProvider((artist.id, LibraryItemType.artist)),
    );
    final localAlbums = ref.watch(
      libraryIndexProvider.select((index) => index.albumsByArtist[artist.id]),
    );
    final albums = remoteAlbums.value ?? localAlbums ?? const <LibraryItem>[];
    final popular =
        (ref.watch(artistTopTracksProvider(artist.id)).value ??
                const <LibraryItem>[])
            .take(5)
            .toList(growable: false);
    final controller = ref.read(appControllerProvider.notifier);
    return DetailPage(
      title: artist.name,
      typeLabel: 'Artist',
      tint: ref.artworkColor(artist),
      artwork: Artwork(item: artist, borderRadius: 999, iconSize: 72),
      metadata: Text(
        albums.isEmpty
            ? 'Artist'
            : '${albums.length} ${albums.length == 1 ? 'album' : 'albums'}',
        style: _metadataStyle,
      ),
      appBarActions: [ItemMenuButton(item: artist)],
      actions: DetailActionRow(
        play: ContextPlayButton(
          isPlayingFrom: (current) => current.artistId == artist.id,
          onPlay: () => controller.play(artist),
        ),
        shuffle: _shuffleButton(() => controller.shufflePlay(artist), desktop),
        utilities: [
          const SizedBox(width: 8),
          FollowButton(item: artist),
          if (desktop) ItemMenuButton(item: artist, size: 28),
        ],
      ),
      slivers: [
        if (popular.isNotEmpty) ...[
          const SliverSectionHeading('Popular'),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: desktop ? 8 : 0),
            sliver: SliverList.builder(
              itemCount: popular.length,
              itemBuilder: (context, index) {
                final track = popular[index];
                void play() => controller.playQueue(popular, startWith: track);
                return desktop
                    ? TrackRow(
                        index: index + 1,
                        track: track,
                        showAlbum: false,
                        onTap: play,
                      )
                    : MobileTrackTile(track: track, onTap: play);
              },
            ),
          ),
        ],
        if (albums.isNotEmpty) ...[
          const SliverSectionHeading('Discography'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverArtworkGrid(
              items: albums,
              cardSubtitle: (album) => [
                if (album.productionYear case final year?) '$year',
                'Album',
              ].join(' • '),
            ),
          ),
        ] else if (remoteAlbums.isLoading)
          const SliverPadding(
            padding: EdgeInsets.all(40),
            sliver: SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
      ],
    );
  }
}

class _GenrePage extends ConsumerWidget {
  const _GenrePage({required this.genre});

  final LibraryItem genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktopLayout(context);
    final albums = ref.watch(
      itemChildrenProvider((genre.id, LibraryItemType.genre)),
    );
    final controller = ref.read(appControllerProvider.notifier);
    final list = albums.value ?? const <LibraryItem>[];
    return DetailPage(
      title: genre.name,
      typeLabel: 'Genre',
      tint: ref.artworkColor(genre, fallback: const Color(0xFF503750)),
      artwork: Artwork(item: genre, borderRadius: 4, iconSize: 64),
      metadata: Text(
        list.isEmpty
            ? 'Genre'
            : '${list.length} ${list.length == 1 ? 'album' : 'albums'}',
        style: _metadataStyle,
      ),
      actions: DetailActionRow(
        play: ContextPlayButton(
          // A genre plays a random sample, so there is no stable context to
          // match against; the button always starts a fresh mix.
          isPlayingFrom: (_) => false,
          onPlay: () => controller.play(genre),
        ),
        shuffle: _shuffleButton(() => controller.shufflePlay(genre), desktop),
      ),
      slivers: [
        if (albums.isLoading && list.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.all(40),
            sliver: SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else ...[
          const SliverSectionHeading('Albums'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverArtworkGrid(items: list),
          ),
        ],
      ],
    );
  }
}
