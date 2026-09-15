import 'package:flutter/foundation.dart';

enum LibraryItemType { album, artist, track, playlist, genre, folder, unknown }

enum DownloadStatus { queued, downloading, paused, complete, failed }

enum RepeatMode { off, all, one }

class OperationContext {
  const OperationContext({
    required this.profileId,
    required this.generation,
    required this.isCurrentCallback,
  });

  final String profileId;
  final int generation;
  final bool Function() isCurrentCallback;

  bool get isCurrent => isCurrentCallback();

  void throwIfObsolete() {
    if (!isCurrent) throw const ObsoleteOperation();
  }
}

class ObsoleteOperation implements Exception {
  const ObsoleteOperation();
}

@immutable
class ServerProfile {
  const ServerProfile({
    required this.profileId,
    required this.serverId,
    required this.baseUrl,
    required this.name,
    required this.userId,
    required this.username,
    required this.deviceId,
    required this.serverVersion,
    this.allowPrivateHttp = false,
  });

  /// Local identity for one account. Unlike [serverId], this remains unique
  /// when multiple Jellyfin users sign into the same server.
  final String profileId;
  final String serverId;
  final Uri baseUrl;
  final String name;
  final String userId;
  final String username;
  final String deviceId;
  final String serverVersion;
  final bool allowPrivateHttp;
}

@immutable
class AuthSession {
  const AuthSession({required this.profile, required this.token});

  final ServerProfile profile;
  final String token;
}

@immutable
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.profileId,
    required this.serverId,
    required this.type,
    required this.name,
    this.subtitle,
    this.albumId,
    this.albumName,
    this.artistId,
    this.artists = const [],
    this.imageUrl,
    this.duration = Duration.zero,
    this.indexNumber,
    this.discNumber,
    this.productionYear,
    this.isFavorite = false,
    this.hasPrimaryImage = false,
    this.container,
    this.dateCreated,
  });

  final String id;
  final String profileId;
  final String serverId;
  final LibraryItemType type;
  final String name;
  final String? subtitle;
  final String? albumId;
  final String? albumName;
  final String? artistId;
  final List<String> artists;
  final Uri? imageUrl;
  final Duration duration;
  final int? indexNumber;
  final int? discNumber;
  final int? productionYear;
  final bool isFavorite;
  final bool hasPrimaryImage;
  final String? container;

  /// When the item was added to the server, for "Recently added" sorting.
  final DateTime? dateCreated;

  /// Artist credit for display: explicit artists, else the album artist.
  String get artistLine =>
      artists.isNotEmpty ? artists.join(', ') : subtitle ?? 'Unknown artist';

  LibraryItem copyWith({bool? isFavorite, Uri? imageUrl}) {
    return LibraryItem(
      id: id,
      profileId: profileId,
      serverId: serverId,
      type: type,
      name: name,
      subtitle: subtitle,
      albumId: albumId,
      albumName: albumName,
      artistId: artistId,
      artists: artists,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration,
      indexNumber: indexNumber,
      discNumber: discNumber,
      productionYear: productionYear,
      isFavorite: isFavorite ?? this.isFavorite,
      hasPrimaryImage: hasPrimaryImage,
      container: container,
      dateCreated: dateCreated,
    );
  }
}

/// Disc, then track number; unnumbered tracks sort last.
int compareTrackOrder(LibraryItem left, LibraryItem right) {
  final disc = (left.discNumber ?? 0).compareTo(right.discNumber ?? 0);
  if (disc != 0) return disc;
  return (left.indexNumber ?? 9999).compareTo(right.indexNumber ?? 9999);
}

@immutable
class LyricsLine {
  const LyricsLine({required this.text, this.start});

  final String text;
  final Duration? start;
}

@immutable
class PlaybackQueue {
  const PlaybackQueue({
    this.items = const [],
    this.currentIndex = -1,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
    this.playOrder = const [],
  });

  final List<LibraryItem> items;
  final int currentIndex;
  final bool shuffle;
  final RepeatMode repeatMode;

  /// Indices into [items] in the order they will play; differs from the
  /// natural order while shuffled. Empty means natural order.
  final List<int> playOrder;

  LibraryItem? get current => currentIndex >= 0 && currentIndex < items.length
      ? items[currentIndex]
      : null;

  /// Indices of the items that play after [current], in play order.
  List<int> get upNextIndices {
    if (current == null) return const [];
    final order = playOrder.length == items.length
        ? playOrder
        : List<int>.generate(items.length, (index) => index);
    final position = order.indexOf(currentIndex);
    return position < 0 ? const [] : order.sublist(position + 1);
  }

  // Snapshots are emitted on every position tick; identity checks on the
  // lists keep equality O(1) since the handler only replaces them on change.
  @override
  bool operator ==(Object other) {
    return other is PlaybackQueue &&
        identical(other.items, items) &&
        identical(other.playOrder, playOrder) &&
        other.currentIndex == currentIndex &&
        other.shuffle == shuffle &&
        other.repeatMode == repeatMode;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(items),
    identityHashCode(playOrder),
    currentIndex,
    shuffle,
    repeatMode,
  );
}

@immutable
class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.queue = const PlaybackQueue(),
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.playing = false,
    this.buffering = false,
    this.volume = 1,
    this.sleepDeadline,
  });

  final PlaybackQueue queue;
  final Duration position;
  final Duration bufferedPosition;
  final bool playing;
  final bool buffering;
  final double volume;
  final DateTime? sleepDeadline;

  PlaybackSnapshot copyWith({
    PlaybackQueue? queue,
    Duration? position,
    bool? playing,
    bool? buffering,
    DateTime? sleepDeadline,
    bool clearSleepDeadline = false,
  }) {
    return PlaybackSnapshot(
      queue: queue ?? this.queue,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition,
      playing: playing ?? this.playing,
      buffering: buffering ?? this.buffering,
      volume: volume,
      sleepDeadline: clearSleepDeadline
          ? null
          : sleepDeadline ?? this.sleepDeadline,
    );
  }
}

@immutable
class DownloadRecord {
  const DownloadRecord({
    required this.id,
    required this.profileId,
    required this.itemId,
    required this.status,
    this.filePath,
    this.progress = 0,
    this.sizeBytes = 0,
    this.lastPlayedAt,
  });

  final String id;
  final String profileId;
  final String itemId;
  final DownloadStatus status;
  final String? filePath;
  final double progress;
  final int sizeBytes;
  final DateTime? lastPlayedAt;
}

@immutable
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.googleCast,
    required this.airPlay,
    required this.equalizer,
    required this.automotive,
    required this.desktopMediaKeys,
    this.castConnected = false,
  });

  final bool googleCast;
  final bool airPlay;
  final bool equalizer;
  final bool automotive;
  final bool desktopMediaKeys;
  final bool castConnected;
}

@immutable
class CastTarget {
  const CastTarget({required this.id, required this.name, this.model});

  final String id;
  final String name;
  final String? model;
}

@immutable
class RemotePlaybackState {
  const RemotePlaybackState({
    this.connected = false,
    this.playing = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.itemId,
  });

  final bool connected;
  final bool playing;
  final bool buffering;
  final Duration position;
  final String? itemId;
}

@immutable
class ServerInfo {
  const ServerInfo({
    required this.id,
    required this.name,
    required this.version,
  });

  final String id;
  final String name;
  final String version;
}

@immutable
class LibraryPage {
  const LibraryPage({
    required this.items,
    required this.startIndex,
    this.totalRecordCount,
  });

  final List<LibraryItem> items;
  final int startIndex;
  final int? totalRecordCount;
}
