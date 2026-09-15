import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/domain/models.dart';

/// Opens [item]'s page; a track opens its album.
void openItem(BuildContext context, LibraryItem item) {
  if (item.type == LibraryItemType.track) {
    if (item.albumId case final albumId?) context.push('/item/$albumId');
    return;
  }
  context.push('/item/${item.id}', extra: item);
}

/// Opens the artist credited on [item], or [item] itself for an artist.
void openArtist(BuildContext context, LibraryItem item) {
  final artistId = item.type == LibraryItemType.artist
      ? item.id
      : item.artistId;
  if (artistId != null) context.push('/item/$artistId');
}

String itemTypeLabel(LibraryItemType type) {
  return switch (type) {
    LibraryItemType.album => 'Album',
    LibraryItemType.artist => 'Artist',
    LibraryItemType.track => 'Song',
    LibraryItemType.playlist => 'Playlist',
    LibraryItemType.genre => 'Genre',
    LibraryItemType.folder => 'Folder',
    LibraryItemType.unknown => 'Item',
  };
}

/// The secondary line under a card or row title.
String itemSubtitle(LibraryItem item) {
  return switch (item.type) {
    LibraryItemType.artist => 'Artist',
    LibraryItemType.playlist => 'Playlist',
    LibraryItemType.genre => 'Genre',
    LibraryItemType.album => [
      if (item.productionYear case final year?) '$year',
      item.subtitle?.isNotEmpty ?? false ? item.subtitle! : 'Album',
    ].join(' • '),
    _ => item.artistLine,
  };
}
