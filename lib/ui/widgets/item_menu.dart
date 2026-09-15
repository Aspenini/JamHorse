import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/navigation.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

enum _MenuAction {
  play('Play', Icons.play_arrow_rounded),
  playNext('Play next', Icons.queue_play_next_rounded),
  addToQueue('Add to queue', Icons.add_to_queue_rounded),
  addToPlaylist('Add to playlist', Icons.playlist_add_rounded),
  like('Save to Liked Songs', Icons.favorite_border_rounded),
  unlike('Remove from Liked Songs', Icons.favorite_rounded),
  download('Download', Icons.download_for_offline_outlined),
  goToAlbum('Go to album', Icons.album_outlined),
  goToArtist('Go to artist', Icons.person_outline_rounded);

  const _MenuAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Spotify's context menu for a track, album, artist, or playlist: a popup
/// at [position] (right-click), or a bottom sheet when [position] is null.
Future<void> showItemMenu(
  BuildContext context,
  WidgetRef ref,
  LibraryItem item, {
  Offset? position,
}) async {
  // The container outlives this widget if it is disposed while the menu is
  // open, so actions never touch a stale WidgetRef.
  final container = ProviderScope.containerOf(context, listen: false);
  final live = container.read(libraryIndexProvider).byId[item.id] ?? item;
  final actions = _actionsFor(live);
  final action = position == null
      ? await _showSheet(context, live, actions)
      : await _showPopup(context, position, actions);
  if (action == null || !context.mounted) return;
  await _perform(context, container, live, action);
}

List<_MenuAction> _actionsFor(LibraryItem item) {
  final track = item.type == LibraryItemType.track;
  final liked = item.isFavorite;
  return [
    _MenuAction.play,
    _MenuAction.playNext,
    _MenuAction.addToQueue,
    if (item.type != LibraryItemType.playlist) _MenuAction.addToPlaylist,
    if (track) liked ? _MenuAction.unlike : _MenuAction.like,
    _MenuAction.download,
    if (track && item.albumId != null) _MenuAction.goToAlbum,
    if (item.type != LibraryItemType.artist && item.artistId != null)
      _MenuAction.goToArtist,
  ];
}

Future<_MenuAction?> _showPopup(
  BuildContext context,
  Offset position,
  List<_MenuAction> actions,
) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return showMenu<_MenuAction>(
    context: context,
    color: const Color(0xFF282828),
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      for (final action in actions)
        PopupMenuItem(
          value: action,
          height: 40,
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: JamColors.muted),
              const SizedBox(width: 12),
              Text(action.label),
            ],
          ),
        ),
    ],
  );
}

Future<_MenuAction?> _showSheet(
  BuildContext context,
  LibraryItem item,
  List<_MenuAction> actions,
) {
  return showModalBottomSheet<_MenuAction>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF282828),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: SizedBox.square(
                dimension: 48,
                child: Artwork(
                  item: item,
                  borderRadius: item.type == LibraryItemType.artist ? 24 : 4,
                  iconSize: 20,
                ),
              ),
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                itemSubtitle(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            for (final action in actions)
              ListTile(
                leading: Icon(action.icon),
                title: Text(action.label),
                onTap: () => Navigator.pop(context, action),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _perform(
  BuildContext context,
  ProviderContainer container,
  LibraryItem item,
  _MenuAction action,
) async {
  final controller = container.read(appControllerProvider.notifier);
  final messenger = ScaffoldMessenger.maybeOf(context);
  void notify(String message) =>
      messenger?.showSnackBar(SnackBar(content: Text(message)));
  try {
    switch (action) {
      case _MenuAction.play:
        await controller.play(item);
      case _MenuAction.playNext:
        await controller.playNext(item);
        notify('Playing next');
      case _MenuAction.addToQueue:
        await controller.addToQueue(item);
        notify('Added to queue');
      case _MenuAction.addToPlaylist:
        await showAddToPlaylistDialog(context, container, item);
      case _MenuAction.like || _MenuAction.unlike:
        await controller.toggleFavorite(item);
      case _MenuAction.download:
        notify('Downloading ${item.name}');
        await controller.download(item);
      case _MenuAction.goToAlbum:
        if (item.albumId case final albumId?) context.push('/item/$albumId');
      case _MenuAction.goToArtist:
        openArtist(context, item);
    }
  } catch (error) {
    notify("Couldn't ${action.label.toLowerCase()}: $error");
  }
}

/// "More options" button that opens [showItemMenu] anchored below itself on
/// desktop, or as a bottom sheet on phones.
class ItemMenuButton extends ConsumerWidget {
  const ItemMenuButton({required this.item, super.key, this.size = 22});

  final LibraryItem item;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'More options for ${item.name}',
      iconSize: size,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        Offset? position;
        if (isDesktopLayout(context)) {
          final box = context.findRenderObject()! as RenderBox;
          position = box.localToGlobal(box.size.bottomLeft(Offset.zero));
        }
        showItemMenu(context, ref, item, position: position);
      },
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}

const _newPlaylist = Object();

Future<void> showAddToPlaylistDialog(
  BuildContext context,
  ProviderContainer container,
  LibraryItem item,
) async {
  final playlists = container.read(libraryIndexProvider).playlists;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final choice = await showDialog<Object>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Add to playlist'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, _newPlaylist),
          child: const ListTile(
            leading: Icon(Icons.add_rounded),
            title: Text('New playlist'),
          ),
        ),
        for (final playlist in playlists)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, playlist),
            child: ListTile(
              leading: SizedBox.square(
                dimension: 40,
                child: Artwork(item: playlist, borderRadius: 4, iconSize: 18),
              ),
              title: Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    ),
  );
  var target = choice is LibraryItem ? choice : null;
  if (identical(choice, _newPlaylist)) {
    if (!context.mounted) return;
    target = await showCreatePlaylistDialog(context, container);
  }
  if (target == null) return;
  final count = await container
      .read(appControllerProvider.notifier)
      .addToPlaylist(target, item);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        'Added ${count == 1 ? '1 song' : '$count songs'} to ${target.name}',
      ),
    ),
  );
}

/// Asks for a name and creates an empty Jellyfin playlist.
Future<LibraryItem?> showCreatePlaylistDialog(
  BuildContext context,
  ProviderContainer container,
) async {
  final count = container.read(libraryIndexProvider).playlists.length;
  final name = await showDialog<String>(
    context: context,
    builder: (context) =>
        _PlaylistNameDialog(initial: 'My Playlist #${count + 1}'),
  );
  if (name == null || name.trim().isEmpty) return null;
  return container.read(appControllerProvider.notifier).createPlaylist(name);
}

class _PlaylistNameDialog extends StatefulWidget {
  const _PlaylistNameDialog({required this.initial});

  final String initial;

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create playlist'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Playlist name'),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
