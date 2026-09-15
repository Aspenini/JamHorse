import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/state/ui_state.dart';

LibraryItem _item(
  String id,
  LibraryItemType type, {
  String? name,
  String? subtitle,
  String? albumId,
  String? albumName,
  String? artistId,
  int? disc,
  int? index,
  bool favorite = false,
  DateTime? added,
}) {
  return LibraryItem(
    id: id,
    profileId: 'profile',
    serverId: 'server',
    type: type,
    name: name ?? id,
    subtitle: subtitle,
    albumId: albumId,
    albumName: albumName,
    artistId: artistId,
    discNumber: disc,
    indexNumber: index,
    isFavorite: favorite,
    dateCreated: added,
  );
}

final _library = [
  _item(
    'album-b',
    LibraryItemType.album,
    name: 'Blue',
    subtitle: 'Zed',
    artistId: 'artist-1',
    added: DateTime(2024),
  ),
  _item(
    'album-a',
    LibraryItemType.album,
    name: 'Amber',
    subtitle: 'Abe',
    added: DateTime(2026),
  ),
  _item('artist-1', LibraryItemType.artist, favorite: true),
  _item('artist-2', LibraryItemType.artist),
  _item(
    'playlist',
    LibraryItemType.playlist,
    name: 'Mix',
    added: DateTime(2025),
  ),
  _item('genre', LibraryItemType.genre),
  _item(
    'track-2',
    LibraryItemType.track,
    albumId: 'album-b',
    disc: 1,
    index: 2,
    favorite: true,
  ),
  _item(
    'track-3',
    LibraryItemType.track,
    albumId: 'album-b',
    disc: 2,
    index: 1,
  ),
  _item(
    'track-1',
    LibraryItemType.track,
    albumId: 'album-b',
    disc: 1,
    index: 1,
  ),
  _item(
    'track-a',
    LibraryItemType.track,
    albumId: 'album-a',
    albumName: 'Amber',
  ),
];

void main() {
  test('the index groups library items once', () {
    final index = LibraryIndex.build(_library);

    expect(index.albums, hasLength(2));
    expect(index.artists, hasLength(2));
    expect(index.playlists.single.id, 'playlist');
    expect(index.genres.single.id, 'genre');
    expect(index.likedTracks.single.id, 'track-2');
    expect(index.tracksByAlbum['album-b']!.map((track) => track.id), [
      'track-1',
      'track-2',
      'track-3',
    ]);
    expect(index.albumsByArtist['artist-1']!.single.id, 'album-b');
    expect(index.albumName(index.byId['track-1']!), 'Blue');
    expect(index.albumName(index.byId['track-a']!), 'Amber');
  });

  group('library view', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          libraryIndexProvider.overrideWithValue(LibraryIndex.build(_library)),
          downloadedItemIdsProvider.overrideWithValue(const {'track-a'}),
        ],
      );
    });

    tearDown(() => container.dispose());

    List<String> entries() =>
        container.read(libraryEntriesProvider).map((item) => item.id).toList();

    LibraryViewController view() =>
        container.read(libraryViewProvider.notifier);

    test('shows playlists, albums, and followed artists, newest first', () {
      expect(entries(), ['album-a', 'playlist', 'album-b', 'artist-1']);
    });

    test('filters narrow the list and toggle off again', () {
      view().toggleFilter(LibraryFilter.artists);
      expect(entries(), unorderedEquals(['artist-1', 'artist-2']));

      view().toggleFilter(LibraryFilter.downloaded);
      expect(entries(), ['album-a']);

      view().toggleFilter(LibraryFilter.downloaded);
      expect(container.read(libraryViewProvider).filter, isNull);
    });

    test('search and sort apply on top of the filter', () {
      view()
        ..toggleFilter(LibraryFilter.albums)
        ..setSort(LibrarySort.alphabetical);
      expect(entries(), ['album-a', 'album-b']);

      view().setSort(LibrarySort.creator);
      expect(entries(), ['album-a', 'album-b']);

      view().setQuery('blu');
      expect(entries(), ['album-b']);
    });
  });
}
