import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/theme.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:jamhorse/ui/widgets/artwork.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profileId = state.session?.profile.profileId;
    final records = (ref.watch(downloadRecordsProvider).value ?? const [])
        .where((record) => record.profileId == profileId)
        .toList(growable: false);
    final library = state.library;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Downloads',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
          if (records.isEmpty)
            const SliverFillRemaining(child: _EmptyDownloads())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
              sliver: SliverList.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final item = library
                      .where(
                        (entry) =>
                            entry.profileId == record.profileId &&
                            entry.id == record.itemId,
                      )
                      .firstOrNull;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    hoverColor: JamColors.softHover,
                    leading: item == null
                        ? const SizedBox.square(
                            dimension: 52,
                            child: Icon(Icons.music_note_rounded),
                          )
                        : SizedBox.square(
                            dimension: 52,
                            child: Artwork(
                              item: item,
                              borderRadius: 9,
                              iconSize: 22,
                            ),
                          ),
                    title: Text(item?.name ?? 'Downloaded track'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusLabel(record.status)),
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
                        : () => ref
                              .read(appControllerProvider.notifier)
                              .play(item),
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
    final session = ref.watch(appControllerProvider).session;
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
        tooltip: 'Delete download',
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
              'Long-press an album, playlist, or song to download it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: JamColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
