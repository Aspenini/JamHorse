import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/core/server_uri_policy.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';

class DioJellyfinGateway implements JellyfinGateway {
  DioJellyfinGateway({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 12)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 20)
      ..followRedirects = false
      ..validateStatus = (status) => status != null && status < 400;
  }

  final Dio _dio;

  static bool isSupportedServerVersion(String version) {
    final parts = version.split('.');
    final major = int.tryParse(parts.first) ?? 0;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return major > 10 || (major == 10 && minor >= 10);
  }

  @override
  Future<AuthSession> authenticate({
    required Uri baseUrl,
    required String username,
    required String password,
    required String deviceId,
    required bool allowPrivateHttp,
  }) async {
    ServerUriPolicy.validate(
      baseUrl,
      allowPrivateHttp: allowPrivateHttp,
    );
    final server = await inspectServer(baseUrl);
    if (!isSupportedServerVersion(server.version)) {
      throw StateError('JamHorse requires Jellyfin 10.10 or newer.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      _url(baseUrl, '/Users/AuthenticateByName'),
      data: {'Username': username.trim(), 'Pw': password},
      options: Options(headers: _headers(deviceId: deviceId)),
    );
    final data = response.data ?? const <String, dynamic>{};
    final user = data['User'] as Map<String, dynamic>? ?? const {};
    final token = data['AccessToken'] as String?;
    final userId = user['Id'] as String?;
    if (token == null || userId == null) {
      throw StateError('Jellyfin did not return a valid session.');
    }
    final profile = ServerProfile(
      id: server.id,
      baseUrl: baseUrl,
      name: server.name,
      userId: userId,
      username: (user['Name'] as String?) ?? username,
      deviceId: deviceId,
      serverVersion: server.version,
      allowPrivateHttp: allowPrivateHttp,
    );
    appLog.info('Authenticated ${profile.username} with ${profile.name}');
    return AuthSession(profile: profile, token: token);
  }

  @override
  Future<ServerInfo> inspectServer(Uri baseUrl) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _url(baseUrl, '/System/Info/Public'),
    );
    final data = response.data ?? const <String, dynamic>{};
    final id = data['Id'] as String?;
    if (id == null || id.isEmpty) {
      throw StateError('This address did not identify a Jellyfin server.');
    }
    return ServerInfo(
      id: id,
      name: (data['ServerName'] as String?) ?? baseUrl.host,
      version: (data['Version'] as String?) ?? '0.0.0',
    );
  }

  @override
  Future<List<LibraryItem>> fetchLibrary(
    AuthSession session, {
    Set<LibraryItemType> types = const {},
    int limit = 200,
    String? parentId,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
  }) async {
    final includeTypes =
        (types.isEmpty
                ? {
                    LibraryItemType.album,
                    LibraryItemType.artist,
                    LibraryItemType.track,
                    LibraryItemType.playlist,
                    LibraryItemType.genre,
                  }
                : types)
            .map(_apiType)
            .where((value) => value.isNotEmpty)
            .join(',');
    final response = await _dio.get<Map<String, dynamic>>(
      _url(
        session.profile.baseUrl,
        '/Users/${session.profile.userId}/Items',
      ),
      queryParameters: {
        'Recursive': true,
        'IncludeItemTypes': includeTypes,
        'Fields':
            'PrimaryImageAspectRatio,Genres,MediaSources,Path,Overview,DateCreated',
        'EnableImages': true,
        'EnableUserData': true,
        'Limit': limit,
        'ParentId': parentId,
        'SearchTerm': searchTerm,
        'SortBy': sortBy ?? 'SortName',
        'SortOrder': sortOrder ?? 'Ascending',
      }..removeWhere((_, value) => value == null),
      options: Options(headers: _sessionHeaders(session)),
    );
    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => _mapItem(session, item))
        .toList(growable: false);
  }

  @override
  Future<List<LibraryItem>> fetchFavorites(AuthSession session) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _url(
        session.profile.baseUrl,
        '/Users/${session.profile.userId}/Items',
      ),
      queryParameters: {
        'Recursive': true,
        'Filters': 'IsFavorite',
        'IncludeItemTypes': 'Audio,MusicAlbum,MusicArtist,Playlist',
        'EnableImages': true,
        'EnableUserData': true,
        'Limit': 50,
        'SortBy': 'SortName',
      },
      options: Options(headers: _sessionHeaders(session)),
    );
    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => _mapItem(session, item))
        .toList(growable: false);
  }

  @override
  Future<List<LibraryItem>> fetchRecentlyPlayed(AuthSession session) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _url(
        session.profile.baseUrl,
        '/Users/${session.profile.userId}/Items',
      ),
      queryParameters: {
        'Recursive': true,
        'IncludeItemTypes': 'Audio,MusicAlbum',
        'EnableImages': true,
        'EnableUserData': true,
        'Limit': 30,
        'SortBy': 'DatePlayed',
        'SortOrder': 'Descending',
      },
      options: Options(headers: _sessionHeaders(session)),
    );
    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => _mapItem(session, item))
        .toList(growable: false);
  }

  @override
  Future<List<LyricsLine>> fetchLyrics(
    AuthSession session,
    String itemId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _url(session.profile.baseUrl, '/Audio/$itemId/Lyrics'),
        options: Options(headers: _sessionHeaders(session)),
      );
      final lines = response.data?['Lyrics'] as List<dynamic>? ?? const [];
      return lines.whereType<Map<String, dynamic>>().map((line) {
        final ticks = line['Start'] as num?;
        return LyricsLine(
          text: (line['Text'] as String?) ?? '',
          start: ticks == null
              ? null
              : Duration(microseconds: (ticks / 10).round()),
        );
      }).where((line) => line.text.isNotEmpty).toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == HttpStatus.notFound) return const [];
      rethrow;
    }
  }

  @override
  Uri imageUri(AuthSession session, String itemId, {int width = 600}) {
    return Uri.parse(
      _url(session.profile.baseUrl, '/Items/$itemId/Images/Primary'),
    ).replace(queryParameters: {'maxWidth': '$width', 'quality': '90'});
  }

  @override
  Map<String, String> playbackHeaders(AuthSession session) {
    return _sessionHeaders(session);
  }

  @override
  Uri streamUri(
    AuthSession session,
    LibraryItem item, {
    int? maxBitrate,
  }) {
    return Uri.parse(
      _url(session.profile.baseUrl, '/Audio/${item.id}/universal'),
    ).replace(
      queryParameters: {
        'UserId': session.profile.userId,
        'DeviceId': session.profile.deviceId,
        'Container': 'opus,mp3,aac,m4a,flac,webma,webm,wav,ogg',
        'TranscodingContainer': 'aac',
        'TranscodingProtocol': 'http',
        'AudioCodec': 'aac',
        'MaxStreamingBitrate': '${maxBitrate ?? 140000000}',
        'EnableRedirection': 'true',
        'EnableRemoteMedia': 'false',
      },
    );
  }

  @override
  Future<void> setFavorite(
    AuthSession session,
    String itemId,
    bool favorite,
  ) async {
    final path =
        '/Users/${session.profile.userId}/FavoriteItems/$itemId';
    final url = _url(session.profile.baseUrl, path);
    final options = Options(headers: _sessionHeaders(session));
    if (favorite) {
      await _dio.post<void>(url, options: options);
    } else {
      await _dio.delete<void>(url, options: options);
    }
  }

  @override
  Future<void> reportPlaybackProgress(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    required bool paused,
  }) {
    return _report(
      session,
      '/Sessions/Playing/Progress',
      item,
      position,
      paused: paused,
    );
  }

  @override
  Future<void> reportPlaybackStarted(
    AuthSession session,
    LibraryItem item,
  ) {
    return _report(
      session,
      '/Sessions/Playing',
      item,
      Duration.zero,
      paused: false,
    );
  }

  @override
  Future<void> reportPlaybackStopped(
    AuthSession session,
    LibraryItem item,
    Duration position,
  ) {
    return _report(
      session,
      '/Sessions/Playing/Stopped',
      item,
      position,
      paused: true,
    );
  }

  Future<void> _report(
    AuthSession session,
    String path,
    LibraryItem item,
    Duration position, {
    required bool paused,
  }) async {
    await _dio.post<void>(
      _url(session.profile.baseUrl, path),
      data: {
        'ItemId': item.id,
        'MediaSourceId': item.id,
        'PositionTicks': position.inMicroseconds * 10,
        'IsPaused': paused,
        'IsMuted': false,
        'PlayMethod': 'DirectStream',
        'PlaySessionId': '${session.profile.deviceId}-${item.id}',
        'RepeatMode': 'RepeatNone',
      },
      options: Options(headers: _sessionHeaders(session)),
    );
  }

  LibraryItem _mapItem(
    AuthSession session,
    Map<String, dynamic> data,
  ) {
    final id = (data['Id'] as String?) ?? '';
    final userData = data['UserData'] as Map<String, dynamic>?;
    final artistItems = data['ArtistItems'] as List<dynamic>?;
    final firstArtist = artistItems
        ?.whereType<Map<String, dynamic>>()
        .firstOrNull;
    return LibraryItem(
      id: id,
      serverId: session.profile.id,
      type: _domainType(data['Type'] as String?),
      name: (data['Name'] as String?) ?? 'Untitled',
      subtitle:
          (data['AlbumArtist'] as String?) ??
          (data['Artists'] as List<dynamic>?)?.whereType<String>().join(', '),
      albumId: data['AlbumId'] as String?,
      artistId: firstArtist?['Id'] as String?,
      imageUrl: id.isEmpty ? null : imageUri(session, id),
      duration: Duration(
        microseconds: (((data['RunTimeTicks'] as num?) ?? 0) / 10).round(),
      ),
      indexNumber: data['IndexNumber'] as int?,
      productionYear: data['ProductionYear'] as int?,
      isFavorite: (userData?['IsFavorite'] as bool?) ?? false,
      container: data['Container'] as String?,
    );
  }

  Map<String, String> _headers({
    required String deviceId,
    String? token,
  }) {
    final tokenPart = token == null ? '' : ', Token="$token"';
    return {
      'Authorization':
          'MediaBrowser Client="JamHorse", Device="JamHorse", '
          'DeviceId="$deviceId", Version="1.0.0"$tokenPart',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _sessionHeaders(AuthSession session) {
    return _headers(
      deviceId: session.profile.deviceId,
      token: session.token,
    );
  }

  String _url(Uri base, String path) {
    final root = base.toString().replaceFirst(RegExp(r'/$'), '');
    return '$root$path';
  }

  String _apiType(LibraryItemType type) {
    return switch (type) {
      LibraryItemType.album => 'MusicAlbum',
      LibraryItemType.artist => 'MusicArtist',
      LibraryItemType.track => 'Audio',
      LibraryItemType.playlist => 'Playlist',
      LibraryItemType.genre => 'MusicGenre',
      LibraryItemType.folder => 'Folder',
      LibraryItemType.unknown => '',
    };
  }

  LibraryItemType _domainType(String? type) {
    return switch (type) {
      'MusicAlbum' => LibraryItemType.album,
      'MusicArtist' || 'Artist' => LibraryItemType.artist,
      'Audio' => LibraryItemType.track,
      'Playlist' => LibraryItemType.playlist,
      'MusicGenre' || 'Genre' => LibraryItemType.genre,
      'Folder' || 'CollectionFolder' => LibraryItemType.folder,
      _ => LibraryItemType.unknown,
    };
  }
}
