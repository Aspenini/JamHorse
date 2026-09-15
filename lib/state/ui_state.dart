import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';

/// What the desktop right-hand panel shows; null when it is closed.
enum RightPanelView { nowPlaying, queue, lyrics }

final rightPanelProvider =
    NotifierProvider<RightPanelController, RightPanelView?>(
      RightPanelController.new,
    );

class RightPanelController extends Notifier<RightPanelView?> {
  @override
  RightPanelView? build() => RightPanelView.nowPlaying;

  void show(RightPanelView view) => state = view;

  /// Opens [view], or closes the panel if [view] is already showing.
  void toggle(RightPanelView view) => state = state == view ? null : view;

  void hide() => state = null;
}

enum LibraryFilter { playlists, albums, artists, downloaded }

enum LibrarySort { recentlyAdded, alphabetical, creator }

@immutable
class LibraryViewState {
  const LibraryViewState({
    this.filter,
    this.sort = LibrarySort.recentlyAdded,
    this.query = '',
    this.grid = true,
  });

  final LibraryFilter? filter;
  final LibrarySort sort;
  final String query;
  final bool grid;

  LibraryViewState copyWith({
    LibraryFilter? filter,
    bool clearFilter = false,
    LibrarySort? sort,
    String? query,
    bool? grid,
  }) {
    return LibraryViewState(
      filter: clearFilter ? null : filter ?? this.filter,
      sort: sort ?? this.sort,
      query: query ?? this.query,
      grid: grid ?? this.grid,
    );
  }
}

/// Filter, sort, and layout of "Your Library", shared by the desktop sidebar
/// and the phone Library tab.
final libraryViewProvider =
    NotifierProvider<LibraryViewController, LibraryViewState>(
      LibraryViewController.new,
    );

class LibraryViewController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryViewState();

  void toggleFilter(LibraryFilter filter) {
    state = state.filter == filter
        ? state.copyWith(clearFilter: true)
        : state.copyWith(filter: filter);
  }

  void setSort(LibrarySort sort) => state = state.copyWith(sort: sort);

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleGrid() => state = state.copyWith(grid: !state.grid);
}

final libraryEntriesProvider = Provider<List<LibraryItem>>((ref) {
  final index = ref.watch(libraryIndexProvider);
  final view = ref.watch(libraryViewProvider);
  final downloaded = view.filter == LibraryFilter.downloaded
      ? ref.watch(downloadedItemIdsProvider)
      : const <String>{};
  final Iterable<LibraryItem> source = switch (view.filter) {
    null => [
      ...index.playlists,
      ...index.albums,
      ...index.artists.where((artist) => artist.isFavorite),
    ],
    LibraryFilter.playlists => index.playlists,
    LibraryFilter.albums => index.albums,
    LibraryFilter.artists => index.artists,
    LibraryFilter.downloaded => index.albums.where(
      (album) =>
          index.tracksByAlbum[album.id]?.any(
            (track) => downloaded.contains(track.id),
          ) ??
          false,
    ),
  };
  final query = view.query.trim().toLowerCase();
  final entries = query.isEmpty
      ? source.toList()
      : source
            .where(
              (item) => '${item.name} ${item.subtitle ?? ''}'
                  .toLowerCase()
                  .contains(query),
            )
            .toList();
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  int byName(LibraryItem a, LibraryItem b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  // mergeSort is stable, so ties keep the library's name order.
  mergeSort<LibraryItem>(
    entries,
    compare: switch (view.sort) {
      LibrarySort.recentlyAdded => (a, b) => (b.dateCreated ?? epoch).compareTo(
        a.dateCreated ?? epoch,
      ),
      LibrarySort.alphabetical => byName,
      LibrarySort.creator => (a, b) {
        final creator = (a.subtitle ?? '').toLowerCase().compareTo(
          (b.subtitle ?? '').toLowerCase(),
        );
        return creator != 0 ? creator : byName(a, b);
      },
    },
  );
  return List.unmodifiable(entries);
});
