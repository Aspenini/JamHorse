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
    final records = ref.watch(downloadRecordsProvider).value ?? const [];
    final library = ref.watch(appControllerProvider).library;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Downloads',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: JamColors.ink,
      ),
      body: records.isEmpty
          ? const _EmptyDownloads()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
              itemCount: records.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                final item = library
                    .where((entry) => entry.id == record.itemId)
                    .firstOrNull;
                return ListTile(
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
                  trailing: _DownloadAction(record: record),
                  onTap: item == null ||
                          record.status != DownloadStatus.complete
                      ? null
                      : () => ref
                          .read(appControllerProvider.notifier)
                          .play(item),
                );
              },
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
  const _DownloadAction({required this.record});

  final DownloadRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.read(downloadManagerProvider);
    return switch (record.status) {
      DownloadStatus.downloading => IconButton(
        tooltip: 'Pause',
        onPressed: () => manager.pause(record.id),
        icon: const Icon(Icons.pause_rounded),
      ),
      DownloadStatus.paused || DownloadStatus.failed => IconButton(
        tooltip: 'Resume',
        onPressed: () => manager.resume(record.id),
        icon: const Icon(Icons.play_arrow_rounded),
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
