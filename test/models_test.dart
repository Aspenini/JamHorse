import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/domain/models.dart';

void main() {
  test('operation context exposes generation and accepts current work', () {
    final context = OperationContext(
      profileId: 'profile',
      generation: 3,
      isCurrentCallback: () => true,
    );

    expect(context.profileId, 'profile');
    expect(context.generation, 3);
    expect(context.isCurrent, isTrue);
    expect(context.throwIfObsolete, returnsNormally);
  });

  test('library metadata copy preserves fields and updates mutable flags', () {
    final original = LibraryItem(
      id: 'track',
      profileId: 'profile',
      serverId: 'server',
      type: LibraryItemType.track,
      name: 'Song',
      subtitle: 'Artist',
      albumId: 'album',
      albumName: 'Record',
      artistId: 'artist',
      artists: const ['One', 'Two'],
      imageUrl: Uri.parse('https://example.com/old.jpg'),
      duration: const Duration(minutes: 3),
      indexNumber: 4,
      discNumber: 2,
      productionYear: 2026,
      hasPrimaryImage: true,
      container: 'flac',
    );

    final updated = original.copyWith(
      isFavorite: true,
      imageUrl: Uri.parse('https://example.com/new.jpg'),
    );

    expect(updated.id, original.id);
    expect(updated.profileId, original.profileId);
    expect(updated.serverId, original.serverId);
    expect(updated.type, original.type);
    expect(updated.name, original.name);
    expect(updated.subtitle, original.subtitle);
    expect(updated.albumId, original.albumId);
    expect(updated.albumName, original.albumName);
    expect(updated.artistId, original.artistId);
    expect(updated.artists, original.artists);
    expect(updated.duration, original.duration);
    expect(updated.indexNumber, original.indexNumber);
    expect(updated.discNumber, original.discNumber);
    expect(updated.productionYear, original.productionYear);
    expect(updated.hasPrimaryImage, isTrue);
    expect(updated.container, 'flac');
    expect(updated.isFavorite, isTrue);
    expect(updated.imageUrl.toString(), endsWith('/new.jpg'));
  });

  test('playback queue current is bounds checked', () {
    const item = LibraryItem(
      id: 'track',
      profileId: 'profile',
      serverId: 'server',
      type: LibraryItemType.track,
      name: 'Song',
    );

    expect(const PlaybackQueue().current, isNull);
    expect(const PlaybackQueue(items: [item], currentIndex: 1).current, isNull);
    expect(
      const PlaybackQueue(items: [item], currentIndex: 0).current,
      same(item),
    );
  });

  test('domain wrappers and capability records retain their values', () {
    const item = LibraryItem(
      id: 'track',
      profileId: 'profile',
      serverId: 'server',
      type: LibraryItemType.track,
      name: 'Song',
    );
    const snapshot = PlaybackSnapshot(
      queue: PlaybackQueue(items: [item], currentIndex: 0),
      playing: true,
    );
    const download = DownloadRecord(
      id: 'download',
      profileId: 'profile',
      itemId: 'track',
      status: DownloadStatus.complete,
    );
    const capabilities = PlatformCapabilities(
      googleCast: true,
      airPlay: true,
      equalizer: false,
      automotive: true,
      desktopMediaKeys: true,
    );
    const target = CastTarget(id: 'cast', name: 'Living room');
    const remote = RemotePlaybackState(
      connected: true,
      playing: true,
      position: Duration(seconds: 12),
      itemId: 'track',
    );
    final discovered = DiscoveredServer(
      name: 'Music',
      address: Uri.parse('https://music.example.com'),
    );

    expect(snapshot.queue.current, item);
    expect(download.status, DownloadStatus.complete);
    expect(capabilities.googleCast, isTrue);
    expect(target.name, 'Living room');
    expect(remote.position, const Duration(seconds: 12));
    expect(discovered.address.host, 'music.example.com');
  });
}
