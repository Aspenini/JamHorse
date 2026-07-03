import 'package:flutter/foundation.dart';

enum LibraryItemType { album, artist, track, playlist, genre, folder, unknown }

enum DownloadStatus { queued, downloading, paused, complete, failed }

enum RepeatMode { off, all, one }

@immutable
class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.baseUrl,
    required this.name,
    required this.userId,
    required this.username,
    required this.deviceId,
    required this.serverVersion,
    this.allowPrivateHttp = false,
  });

  final String id;
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
    required this.serverId,
    required this.type,
    required this.name,
    this.subtitle,
    this.albumId,
    this.artistId,
    this.imageUrl,
    this.duration = Duration.zero,
    this.indexNumber,
    this.productionYear,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.container,
  });

  final String id;
  final String serverId;
  final LibraryItemType type;
  final String name;
  final String? subtitle;
  final String? albumId;
  final String? artistId;
  final Uri? imageUrl;
  final Duration duration;
  final int? indexNumber;
  final int? productionYear;
  final bool isFavorite;
  final bool isDownloaded;
  final String? container;

  LibraryItem copyWith({
    bool? isFavorite,
    bool? isDownloaded,
    Uri? imageUrl,
  }) {
    return LibraryItem(
      id: id,
      serverId: serverId,
      type: type,
      name: name,
      subtitle: subtitle,
      albumId: albumId,
      artistId: artistId,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration,
      indexNumber: indexNumber,
      productionYear: productionYear,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      container: container,
    );
  }
}

@immutable
class Track {
  const Track(this.item);

  final LibraryItem item;
}

@immutable
class Album {
  const Album(this.item, {this.tracks = const []});

  final LibraryItem item;
  final List<Track> tracks;
}

@immutable
class Artist {
  const Artist(this.item, {this.albums = const []});

  final LibraryItem item;
  final List<Album> albums;
}

@immutable
class Playlist {
  const Playlist(this.item, {this.tracks = const []});

  final LibraryItem item;
  final List<Track> tracks;
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
  });

  final List<LibraryItem> items;
  final int currentIndex;
  final bool shuffle;
  final RepeatMode repeatMode;

  LibraryItem? get current =>
      currentIndex >= 0 && currentIndex < items.length
          ? items[currentIndex]
          : null;
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
  });

  final PlaybackQueue queue;
  final Duration position;
  final Duration bufferedPosition;
  final bool playing;
  final bool buffering;
  final double volume;
}

@immutable
class DownloadRecord {
  const DownloadRecord({
    required this.id,
    required this.serverId,
    required this.itemId,
    required this.status,
    this.filePath,
    this.progress = 0,
    this.sizeBytes = 0,
    this.checksum,
  });

  final String id;
  final String serverId;
  final String itemId;
  final DownloadStatus status;
  final String? filePath;
  final double progress;
  final int sizeBytes;
  final String? checksum;
}

@immutable
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.googleCast,
    required this.airPlay,
    required this.equalizer,
    required this.automotive,
    required this.desktopMediaKeys,
  });

  final bool googleCast;
  final bool airPlay;
  final bool equalizer;
  final bool automotive;
  final bool desktopMediaKeys;
}

@immutable
class DiscoveredServer {
  const DiscoveredServer({required this.name, required this.address});

  final String name;
  final Uri address;
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
