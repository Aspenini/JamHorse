import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';

/// Every view of the synced library that screens need, computed once per
/// library change instead of filtering the full list inside `build`.
class LibraryIndex {
  LibraryIndex._({
    required this.byId,
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.playlists,
    required this.genres,
    required this.likedTracks,
    required this.tracksByAlbum,
    required this.albumsByArtist,
  });

  factory LibraryIndex.build(List<LibraryItem> items) {
    final byId = <String, LibraryItem>{};
    final tracks = <LibraryItem>[];
    final albums = <LibraryItem>[];
    final artists = <LibraryItem>[];
    final playlists = <LibraryItem>[];
    final genres = <LibraryItem>[];
    final liked = <LibraryItem>[];
    final tracksByAlbum = <String, List<LibraryItem>>{};
    final albumsByArtist = <String, List<LibraryItem>>{};
    for (final item in items) {
      byId[item.id] = item;
      switch (item.type) {
        case LibraryItemType.track:
          tracks.add(item);
          if (item.isFavorite) liked.add(item);
          if (item.albumId case final albumId?) {
            (tracksByAlbum[albumId] ??= []).add(item);
          }
        case LibraryItemType.album:
          albums.add(item);
          if (item.artistId case final artistId?) {
            (albumsByArtist[artistId] ??= []).add(item);
          }
        case LibraryItemType.artist:
          artists.add(item);
        case LibraryItemType.playlist:
          playlists.add(item);
        case LibraryItemType.genre:
          genres.add(item);
        case LibraryItemType.folder || LibraryItemType.unknown:
          break;
      }
    }
    for (final albumTracks in tracksByAlbum.values) {
      albumTracks.sort(compareTrackOrder);
    }
    return LibraryIndex._(
      byId: byId,
      tracks: List.unmodifiable(tracks),
      albums: List.unmodifiable(albums),
      artists: List.unmodifiable(artists),
      playlists: List.unmodifiable(playlists),
      genres: List.unmodifiable(genres),
      likedTracks: List.unmodifiable(liked),
      tracksByAlbum: tracksByAlbum,
      albumsByArtist: albumsByArtist,
    );
  }

  static final empty = LibraryIndex.build(const []);

  final Map<String, LibraryItem> byId;
  final List<LibraryItem> tracks;
  final List<LibraryItem> albums;
  final List<LibraryItem> artists;
  final List<LibraryItem> playlists;
  final List<LibraryItem> genres;
  final List<LibraryItem> likedTracks;

  /// Tracks per album id, in disc and track order.
  final Map<String, List<LibraryItem>> tracksByAlbum;
  final Map<String, List<LibraryItem>> albumsByArtist;

  String? albumName(LibraryItem track) {
    return track.albumName ??
        (track.albumId == null ? null : byId[track.albumId]?.name);
  }
}

final libraryIndexProvider = Provider<LibraryIndex>((ref) {
  final library = ref.watch(
    appControllerProvider.select((state) => state.library),
  );
  return library.isEmpty ? LibraryIndex.empty : LibraryIndex.build(library);
});
