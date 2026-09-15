import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widths of the desktop library sidebar and right panel, as the user left
/// them. [resolvePanelSizes] fits them to the window.
@immutable
class PanelLayout {
  const PanelLayout({
    this.libraryWidth = defaultLibraryWidth,
    this.libraryCollapsed = false,
    this.rightPanelWidth = defaultRightPanelWidth,
  });

  static const defaultLibraryWidth = 340.0;
  static const collapsedLibraryWidth = 72.0;
  static const minLibraryWidth = 280.0;
  static const maxLibraryWidth = 720.0;

  /// Dragging the library narrower than this collapses it to the rail.
  static const collapseThreshold = 176.0;

  static const defaultRightPanelWidth = 360.0;
  static const minRightPanelWidth = 280.0;
  static const maxRightPanelWidth = 560.0;

  /// The main view never gets narrower than this.
  static const minContentWidth = 360.0;

  final double libraryWidth;
  final bool libraryCollapsed;
  final double rightPanelWidth;

  PanelLayout copyWith({
    double? libraryWidth,
    bool? libraryCollapsed,
    double? rightPanelWidth,
  }) {
    return PanelLayout(
      libraryWidth: libraryWidth ?? this.libraryWidth,
      libraryCollapsed: libraryCollapsed ?? this.libraryCollapsed,
      rightPanelWidth: rightPanelWidth ?? this.rightPanelWidth,
    );
  }
}

typedef PanelSizes = ({
  double library,
  bool libraryCollapsed,
  double rightPanel,
});

/// Fits [layout] into a window [windowWidth] wide. The library shrinks
/// before the right panel does, and collapses to its rail when even its
/// minimum width would squeeze the main view below
/// [PanelLayout.minContentWidth].
PanelSizes resolvePanelSizes({
  required double windowWidth,
  required PanelLayout layout,
  required bool rightPanelOpen,
}) {
  // Outer gutters plus the library's resize handle.
  const chrome = 8.0 * 3;
  const handle = 8.0;
  final desiredPanel = layout.rightPanelWidth.clamp(
    PanelLayout.minRightPanelWidth,
    PanelLayout.maxRightPanelWidth,
  );
  final panelSpace = rightPanelOpen ? desiredPanel + handle : 0.0;
  final roomForLibrary =
      windowWidth - chrome - panelSpace - PanelLayout.minContentWidth;
  final collapsed =
      layout.libraryCollapsed || roomForLibrary < PanelLayout.minLibraryWidth;
  final library = collapsed
      ? PanelLayout.collapsedLibraryWidth
      : layout.libraryWidth.clamp(
          PanelLayout.minLibraryWidth,
          math.min(PanelLayout.maxLibraryWidth, roomForLibrary),
        );
  final roomForPanel =
      windowWidth - chrome - library - handle - PanelLayout.minContentWidth;
  final panel = desiredPanel.clamp(
    PanelLayout.minRightPanelWidth,
    math.max(PanelLayout.minRightPanelWidth, roomForPanel),
  );
  return (
    library: library.toDouble(),
    libraryCollapsed: collapsed,
    rightPanel: panel.toDouble(),
  );
}

final panelLayoutProvider =
    NotifierProvider<PanelLayoutController, PanelLayout>(
      PanelLayoutController.new,
    );

class PanelLayoutController extends Notifier<PanelLayout> {
  static const _libraryWidthKey = 'libraryWidth';
  static const _libraryCollapsedKey = 'libraryCollapsed';
  static const _rightPanelWidthKey = 'rightPanelWidth';

  @override
  PanelLayout build() {
    unawaited(_load());
    return const PanelLayout();
  }

  /// Follows a drag of the library's edge to [width]; dragging far enough
  /// in collapses it, and dragging back out expands it again. Collapsing
  /// restores [widthBeforeDrag] so expanding later returns to where the
  /// user started, not wherever the pointer passed on the way in.
  void dragLibraryTo(double width, {double? widthBeforeDrag}) {
    final restore =
        widthBeforeDrag != null &&
            widthBeforeDrag >= PanelLayout.minLibraryWidth
        ? widthBeforeDrag
        : state.libraryWidth;
    state = width < PanelLayout.collapseThreshold
        ? state.copyWith(libraryCollapsed: true, libraryWidth: restore)
        : state.copyWith(
            libraryCollapsed: false,
            libraryWidth: width.clamp(
              PanelLayout.minLibraryWidth,
              PanelLayout.maxLibraryWidth,
            ),
          );
  }

  void toggleLibrary() {
    state = state.copyWith(libraryCollapsed: !state.libraryCollapsed);
    unawaited(save());
  }

  void resetLibrary() {
    state = state.copyWith(
      libraryCollapsed: false,
      libraryWidth: PanelLayout.defaultLibraryWidth,
    );
    unawaited(save());
  }

  void setRightPanelWidth(double width) {
    state = state.copyWith(
      rightPanelWidth: width.clamp(
        PanelLayout.minRightPanelWidth,
        PanelLayout.maxRightPanelWidth,
      ),
    );
  }

  void resetRightPanel() {
    state = state.copyWith(rightPanelWidth: PanelLayout.defaultRightPanelWidth);
    unawaited(save());
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_libraryWidthKey, state.libraryWidth);
      await prefs.setBool(_libraryCollapsedKey, state.libraryCollapsed);
      await prefs.setDouble(_rightPanelWidthKey, state.rightPanelWidth);
    } catch (error) {
      appLog.fine('Panel widths not saved: $error');
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      state = PanelLayout(
        libraryWidth:
            prefs.getDouble(_libraryWidthKey) ??
            PanelLayout.defaultLibraryWidth,
        libraryCollapsed: prefs.getBool(_libraryCollapsedKey) ?? false,
        rightPanelWidth:
            prefs.getDouble(_rightPanelWidthKey) ??
            PanelLayout.defaultRightPanelWidth,
      );
    } catch (error) {
      appLog.fine('Panel widths unavailable: $error');
    }
  }
}

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
