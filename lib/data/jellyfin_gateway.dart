import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/core/server_uri_policy.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:uuid/uuid.dart';

class DioJellyfinGateway implements JellyfinGateway {
  DioJellyfinGateway({Dio? dio, this.appVersion = 'development'})
    : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 12)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 20)
      ..followRedirects = false
      ..validateStatus = (status) =>
          status != null && status >= 200 && status < 300;
  }

  final Dio _dio;
  final String appVersion;

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
    ServerUriPolicy.validate(baseUrl, allowPrivateHttp: allowPrivateHttp);
    final server = await _inspectServer(
      baseUrl,
      allowPrivateHttp: allowPrivateHttp,
    );
    if (!isSupportedServerVersion(server.version)) {
      throw StateError('JamHorse requires Jellyfin 10.10 or newer.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      _url(
        baseUrl,
        '/Users/AuthenticateByName',
        allowPrivateHttp: allowPrivateHttp,
      ),
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
      profileId: const Uuid().v4(),
      serverId: server.id,
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
    return _inspectServer(baseUrl);
  }

  Future<ServerInfo> _inspectServer(
    Uri baseUrl, {
    bool allowPrivateHttp = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _url(baseUrl, '/System/Info/Public', allowPrivateHttp: allowPrivateHttp),
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
  Future<LibraryPage> fetchLibraryPage(
    AuthSession session, {
    Set<LibraryItemType> types = const {},
    int limit = 200,
    String? parentId,
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
    int startIndex = 0,
    OperationContext? context,
  }) async {
    context?.throwIfObsolete();
    final safeLimit = limit.clamp(1, 500);
    final safeStartIndex = startIndex < 0 ? 0 : startIndex;
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
      _sessionUrl(session, '/Users/${session.profile.userId}/Items'),
      queryParameters: {
        'Recursive': true,
        'IncludeItemTypes': includeTypes,
        'Fields': 'Album,AlbumId,ArtistItems,ParentIndexNumber,DateCreated',
        'EnableImages': true,
        'EnableUserData': true,
        'Limit': safeLimit,
        'StartIndex': safeStartIndex,
        'EnableTotalRecordCount': true,
        'ParentId': parentId,
        'SearchTerm': searchTerm,
        'SortBy': sortBy ?? 'SortName',
        'SortOrder': sortOrder ?? 'Ascending',
      }..removeWhere((_, value) => value == null),
      options: Options(headers: _sessionHeaders(session)),
    );
    context?.throwIfObsolete();
    final items = response.data?['Items'] as List<dynamic>? ?? const [];
    return LibraryPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map((item) => _mapItem(session, item))
          .toList(growable: false),
      startIndex:
          (response.data?['StartIndex'] as num?)?.toInt() ?? safeStartIndex,
      totalRecordCount: (response.data?['TotalRecordCount'] as num?)?.toInt(),
    );
  }

  @override
  Future<List<LibraryItem>> fetchFavorites(AuthSession session) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _sessionUrl(session, '/Users/${session.profile.userId}/Items'),
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
      _sessionUrl(session, '/Users/${session.profile.userId}/Items'),
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
        _sessionUrl(session, '/Audio/$itemId/Lyrics'),
        options: Options(headers: _sessionHeaders(session)),
      );
      final lines = response.data?['Lyrics'] as List<dynamic>? ?? const [];
      return lines
          .whereType<Map<String, dynamic>>()
          .map((line) {
            final ticks = line['Start'] as num?;
            return LyricsLine(
              text: (line['Text'] as String?) ?? '',
              start: ticks == null
                  ? null
                  : Duration(microseconds: (ticks / 10).round()),
            );
          })
          .where((line) => line.text.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == HttpStatus.notFound) return const [];
      rethrow;
    }
  }

  @override
  Uri imageUri(AuthSession session, String itemId, {int width = 600}) {
    return Uri.parse(
      _sessionUrl(session, '/Items/$itemId/Images/Primary'),
    ).replace(queryParameters: {'maxWidth': '$width', 'quality': '90'});
  }

  @override
  Map<String, String> playbackHeaders(AuthSession session) {
    return _sessionHeaders(session);
  }

  @override
  Uri streamUri(AuthSession session, LibraryItem item, {int? maxBitrate}) {
    _validateItemSession(session, item);
    return Uri.parse(
      _sessionUrl(session, '/Audio/${item.id}/universal'),
    ).replace(
      queryParameters: {
        'UserId': session.profile.userId,
        'DeviceId': session.profile.deviceId,
        'Container': 'opus,mp3,aac,m4a,flac,webma,webm,wav,ogg',
        'TranscodingContainer': 'aac',
        'TranscodingProtocol': 'http',
        'AudioCodec': 'aac',
        'MaxStreamingBitrate': '${maxBitrate ?? 140000000}',
        'EnableRedirection': 'false',
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
    final path = '/Users/${session.profile.userId}/FavoriteItems/$itemId';
    final url = _sessionUrl(session, path);
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
    String? playSessionId,
  }) {
    return _report(
      session,
      '/Sessions/Playing/Progress',
      item,
      position,
      paused: paused,
      playSessionId: playSessionId,
    );
  }

  @override
  Future<void> reportPlaybackStarted(
    AuthSession session,
    LibraryItem item, {
    String? playSessionId,
  }) {
    return _report(
      session,
      '/Sessions/Playing',
      item,
      Duration.zero,
      paused: false,
      playSessionId: playSessionId,
    );
  }

  @override
  Future<void> reportPlaybackStopped(
    AuthSession session,
    LibraryItem item,
    Duration position, {
    String? playSessionId,
  }) {
    return _report(
      session,
      '/Sessions/Playing/Stopped',
      item,
      position,
      paused: true,
      playSessionId: playSessionId,
    );
  }

  Future<void> _report(
    AuthSession session,
    String path,
    LibraryItem item,
    Duration position, {
    required bool paused,
    String? playSessionId,
  }) async {
    _validateItemSession(session, item);
    await _dio.post<void>(
      _sessionUrl(session, path),
      data: {
        'ItemId': item.id,
        'MediaSourceId': item.id,
        'PositionTicks': position.inMicroseconds * 10,
        'IsPaused': paused,
        'IsMuted': false,
        'PlayMethod': 'DirectStream',
        'PlaySessionId':
            playSessionId ?? '${session.profile.deviceId}-${item.id}',
        'RepeatMode': 'RepeatNone',
      },
      options: Options(headers: _sessionHeaders(session)),
    );
  }

  LibraryItem _mapItem(AuthSession session, Map<String, dynamic> data) {
    final id = (data['Id'] as String?) ?? '';
    final userData = data['UserData'] as Map<String, dynamic>?;
    final artistItems = data['ArtistItems'] as List<dynamic>?;
    final firstArtist = artistItems
        ?.whereType<Map<String, dynamic>>()
        .firstOrNull;
    final artists =
        (data['Artists'] as List<dynamic>?)?.whereType<String>().toList() ??
        const <String>[];
    final imageTags = data['ImageTags'] as Map<String, dynamic>?;
    final hasPrimaryImage = imageTags?['Primary'] != null;
    return LibraryItem(
      id: id,
      profileId: session.profile.profileId,
      serverId: session.profile.serverId,
      type: _domainType(data['Type'] as String?),
      name: (data['Name'] as String?) ?? 'Untitled',
      subtitle: (data['AlbumArtist'] as String?) ?? artists.join(', '),
      albumId: data['AlbumId'] as String?,
      albumName: data['Album'] as String?,
      artistId: firstArtist?['Id'] as String?,
      artists: artists,
      imageUrl: id.isEmpty || !hasPrimaryImage ? null : imageUri(session, id),
      duration: Duration(
        microseconds: (((data['RunTimeTicks'] as num?) ?? 0) / 10).round(),
      ),
      indexNumber: data['IndexNumber'] as int?,
      discNumber: data['ParentIndexNumber'] as int?,
      productionYear: data['ProductionYear'] as int?,
      isFavorite: (userData?['IsFavorite'] as bool?) ?? false,
      hasPrimaryImage: hasPrimaryImage,
      container: data['Container'] as String?,
    );
  }

  Map<String, String> _headers({required String deviceId, String? token}) {
    final tokenPart = token == null ? '' : ', Token="$token"';
    return {
      'Authorization':
          'MediaBrowser Client="JamHorse", Device="JamHorse", '
          'DeviceId="$deviceId", Version="$appVersion"$tokenPart',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, String> _sessionHeaders(AuthSession session) {
    return _headers(deviceId: session.profile.deviceId, token: session.token);
  }

  String _sessionUrl(AuthSession session, String path) {
    return _url(
      session.profile.baseUrl,
      path,
      allowPrivateHttp: session.profile.allowPrivateHttp,
    );
  }

  String _url(Uri base, String path, {bool allowPrivateHttp = false}) {
    ServerUriPolicy.validate(base, allowPrivateHttp: allowPrivateHttp);
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

  void _validateItemSession(AuthSession session, LibraryItem item) {
    if (item.profileId != session.profile.profileId ||
        item.serverId != session.profile.serverId) {
      throw StateError('This item belongs to a different account profile.');
    }
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
