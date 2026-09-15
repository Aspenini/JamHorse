import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/library_index.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/layout.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';
import 'package:jamhorse/ui/widgets/transport_controls.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktopLayout(context);
    final profileId = ref.watch(
      sessionProvider.select((session) => session?.profile.profileId),
    );
    final records = (ref.watch(downloadRecordsProvider).value ?? const [])
        .where((record) => record.profileId == profileId)
        .toList(growable: false);
    final index = ref.watch(libraryIndexProvider);
    final completed = [
      for (final record in records)
        if (record.status == DownloadStatus.complete)
          ?index.byId[record.itemId],
    ];
    final completedIds = {for (final track in completed) track.id};
    final controller = ref.read(appControllerProvider.notifier);
    return Scaffold(
      backgroundColor: desktop ? Colors.transparent : JamColors.ink,
      appBar: desktop
          ? null
          : AppBar(
              backgroundColor: JamColors.ink,
              title: const Text('Downloads'),
            ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              desktop ? 24 : 16,
              desktop ? 24 : 8,
              16,
              12,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: desktop
                        ? Text(
                            'Downloads',
                            style: Theme.of(context).textTheme.headlineLarge,
                          )
                        : Text(
                            '${completed.length} songs available offline',
                            style: const TextStyle(color: JamColors.muted),
                          ),
                  ),
                  if (completed.isNotEmpty)
                    ContextPlayButton(
                      size: 48,
                      isPlayingFrom: (current) =>
                          completedIds.contains(current.id),
                      onPlay: () => controller.playQueue(completed),
                    ),
                ],
              ),
            ),
          ),
          if (records.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyDownloads(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 120),
              sliver: SliverList.builder(
                itemCount: records.length,
                itemBuilder: (context, position) {
                  final record = records[position];
                  final item = index.byId[record.itemId];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    hoverColor: JamColors.softHover,
                    leading: SizedBox.square(
                      dimension: 48,
                      child: item == null
                          ? const Icon(Icons.music_note_rounded)
                          : Artwork(item: item, borderRadius: 4, iconSize: 20),
                    ),
                    title: Text(
                      item?.name ?? 'Downloaded track',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (item != null) item.artistLine,
                            _statusLabel(record.status),
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (record.status == DownloadStatus.downloading ||
                            record.status == DownloadStatus.queued)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: LinearProgressIndicator(
                              value: record.status == DownloadStatus.queued
                                  ? null
                                  : record.progress,
                            ),
                          ),
                      ],
                    ),
                    trailing: _DownloadAction(record: record, item: item),
                    onTap:
                        item == null || record.status != DownloadStatus.complete
                        ? null
                        : () =>
                              controller.playQueue(completed, startWith: item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.queued => 'Waiting',
      DownloadStatus.downloading => 'Downloading',
      DownloadStatus.paused => 'Paused',
      DownloadStatus.complete => 'Available offline',
      DownloadStatus.failed => 'Download failed',
    };
  }
}

class _DownloadAction extends ConsumerWidget {
  const _DownloadAction({required this.record, required this.item});

  final DownloadRecord record;
  final LibraryItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.read(downloadManagerProvider);
    final session = ref.watch(sessionProvider);
    return switch (record.status) {
      DownloadStatus.downloading => IconButton(
        tooltip: 'Pause',
        onPressed: () => manager.pause(record.id),
        icon: const Icon(Icons.pause_rounded),
      ),
      DownloadStatus.paused => IconButton(
        tooltip: 'Resume',
        onPressed: () => manager.resume(record.id),
        icon: const Icon(Icons.play_arrow_rounded),
      ),
      DownloadStatus.failed => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item != null && session != null)
            IconButton(
              tooltip: 'Retry',
              onPressed: () => manager.retry(record.id, session, item!),
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            tooltip: 'Delete failed download',
            onPressed: () => manager.delete(record.id),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      DownloadStatus.complete => IconButton(
        tooltip: 'Remove download',
        onPressed: () => manager.delete(record.id),
        icon: const Icon(Icons.delete_outline_rounded),
      ),
      DownloadStatus.queued => IconButton(
        tooltip: 'Cancel',
        onPressed: () => manager.cancel(record.id),
        icon: const Icon(Icons.close_rounded),
      ),
    };
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_for_offline_outlined,
              size: 72,
              color: JamColors.muted,
            ),
            const SizedBox(height: 20),
            Text(
              'Keep the good stuff close.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the ••• menu on an album, playlist, or song and choose '
              'Download.',
              textAlign: TextAlign.center,
              style: TextStyle(color: JamColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
