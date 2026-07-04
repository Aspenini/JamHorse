import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/data/jellyfin_gateway.dart';
import 'package:jamhorse/domain/models.dart';

void main() {
  group('DioJellyfinGateway.isSupportedServerVersion', () {
    test('accepts 10.10 and newer', () {
      expect(DioJellyfinGateway.isSupportedServerVersion('10.10.3'), isTrue);
      expect(DioJellyfinGateway.isSupportedServerVersion('10.11.0'), isTrue);
      expect(DioJellyfinGateway.isSupportedServerVersion('11.0.0'), isTrue);
    });

    test('rejects versions older than 10.10', () {
      expect(DioJellyfinGateway.isSupportedServerVersion('10.9.11'), isFalse);
      expect(DioJellyfinGateway.isSupportedServerVersion('10.2.0'), isFalse);
      expect(DioJellyfinGateway.isSupportedServerVersion('9.11.0'), isFalse);
    });

    test('rejects unparseable versions', () {
      expect(DioJellyfinGateway.isSupportedServerVersion(''), isFalse);
      expect(DioJellyfinGateway.isSupportedServerVersion('unknown'), isFalse);
    });
  });

  test(
    'paged library requests carry bounds and map profile metadata',
    () async {
      late RequestOptions request;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = options;
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'StartIndex': 25,
                    'TotalRecordCount': 101,
                    'Items': [
                      {
                        'Id': 'track',
                        'Type': 'Audio',
                        'Name': 'Song',
                        'Album': 'Record',
                        'AlbumId': 'album',
                        'Artists': ['One', 'Two'],
                        'ParentIndexNumber': 2,
                        'ImageTags': {'Primary': 'hash'},
                      },
                    ],
                  },
                ),
              );
            },
          ),
        );
      final gateway = DioJellyfinGateway(dio: dio, appVersion: 'test');

      final page = await gateway.fetchLibraryPage(
        _session(),
        limit: 50,
        startIndex: 25,
        types: {LibraryItemType.track},
        context: OperationContext(
          profileId: 'profile',
          generation: 1,
          isCurrentCallback: () => true,
        ),
      );

      expect(request.queryParameters['Limit'], 50);
      expect(request.queryParameters['StartIndex'], 25);
      expect(request.queryParameters['IncludeItemTypes'], 'Audio');
      expect(request.headers['Authorization'], contains('Token="secret"'));
      expect(page.totalRecordCount, 101);
      expect(page.items.single.profileId, 'profile');
      expect(page.items.single.albumName, 'Record');
      expect(page.items.single.artists, ['One', 'Two']);
      expect(page.items.single.discNumber, 2);
      expect(page.items.single.hasPrimaryImage, isTrue);

      await gateway.fetchLibraryPage(
        _session(),
        types: {
          LibraryItemType.playlist,
          LibraryItemType.genre,
          LibraryItemType.folder,
          LibraryItemType.unknown,
        },
      );
      expect(
        request.queryParameters['IncludeItemTypes'],
        'Playlist,MusicGenre,Folder',
      );
    },
  );

  test('stream URLs never contain credentials', () {
    final gateway = DioJellyfinGateway(appVersion: 'test');
    final session = _session();
    final item = LibraryItem(
      id: 'track',
      profileId: 'profile',
      serverId: 'server',
      type: LibraryItemType.track,
      name: 'Song',
    );

    final uri = gateway.streamUri(session, item);

    expect(uri.queryParameters, isNot(contains('api_key')));
    expect(uri.queryParameters.values, isNot(contains('secret')));
    expect(uri.userInfo, isEmpty);
    expect(
      gateway.playbackHeaders(session)['Authorization'],
      contains('secret'),
    );
  });

  test('private HTTP requests require the saved profile opt-in', () {
    final gateway = DioJellyfinGateway(appVersion: 'test');
    final blocked = AuthSession(
      profile: _session().profile.copyWithPrivateHttp(false),
      token: 'secret',
    );
    final item = LibraryItem(
      id: 'track',
      profileId: 'profile',
      serverId: 'server',
      type: LibraryItemType.track,
      name: 'Song',
    );

    expect(() => gateway.streamUri(blocked, item), throwsFormatException);
  });

  test(
    'authentication and focused gateway endpoints use typed responses',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              final data = switch (options.path) {
                final path when path.endsWith('/System/Info/Public') => {
                  'Id': 'server',
                  'ServerName': 'Music',
                  'Version': '10.10.1',
                },
                final path when path.endsWith('/Users/AuthenticateByName') => {
                  'AccessToken': 'secret',
                  'User': {'Id': 'user', 'Name': 'listener'},
                },
                final path when path.endsWith('/Audio/track/Lyrics') => {
                  'Lyrics': [
                    {'Text': 'First', 'Start': 10000000},
                    {'Text': ''},
                  ],
                },
                final path when path.endsWith('/Items') => {
                  'Items': [
                    {
                      'Id': 'track',
                      'Type': 'Audio',
                      'Name': 'Song',
                      'UserData': {'IsFavorite': true},
                    },
                  ],
                },
                _ => <String, dynamic>{},
              };
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: data,
                ),
              );
            },
          ),
        );
      final gateway = DioJellyfinGateway(dio: dio, appVersion: '0.9.0');

      final session = await gateway.authenticate(
        baseUrl: Uri.parse('https://music.example.com'),
        username: 'listener',
        password: 'password',
        deviceId: 'device',
        allowPrivateHttp: false,
      );
      final recent = await gateway.fetchRecentlyPlayed(session);
      final favorites = await gateway.fetchFavorites(session);
      final lyrics = await gateway.fetchLyrics(session, 'track');

      expect(session.profile.serverId, 'server');
      expect(session.profile.profileId, isNotEmpty);
      expect(session.token, 'secret');
      expect(recent.single.name, 'Song');
      expect(favorites.single.isFavorite, isTrue);
      expect(lyrics.single.text, 'First');
      expect(lyrics.single.start, const Duration(seconds: 1));
      expect(
        requests
            .firstWhere(
              (request) => request.path.endsWith('/Users/AuthenticateByName'),
            )
            .data,
        {'Username': 'listener', 'Pw': 'password'},
      );
    },
  );

  test(
    'favorites and playback reports use headers and explicit sessions',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response<void>(requestOptions: options, statusCode: 204),
              );
            },
          ),
        );
      final gateway = DioJellyfinGateway(dio: dio, appVersion: 'test');
      final session = _session();
      final item = LibraryItem(
        id: 'track',
        profileId: 'profile',
        serverId: 'server',
        type: LibraryItemType.track,
        name: 'Song',
      );

      await gateway.setFavorite(session, item.id, true);
      await gateway.setFavorite(session, item.id, false);
      await gateway.reportPlaybackStarted(
        session,
        item,
        playSessionId: 'play-session',
      );
      await gateway.reportPlaybackProgress(
        session,
        item,
        const Duration(seconds: 12),
        paused: true,
        playSessionId: 'play-session',
      );
      await gateway.reportPlaybackStopped(
        session,
        item,
        const Duration(seconds: 13),
        playSessionId: 'play-session',
      );

      expect(requests[0].method, 'POST');
      expect(requests[1].method, 'DELETE');
      final reports = requests.skip(2).toList();
      expect(reports.map((request) => request.path), [
        endsWith('/Sessions/Playing'),
        endsWith('/Sessions/Playing/Progress'),
        endsWith('/Sessions/Playing/Stopped'),
      ]);
      expect(reports[1].data['PositionTicks'], 120000000);
      expect(reports[1].data['IsPaused'], isTrue);
      expect(reports[1].data['PlaySessionId'], 'play-session');
      expect(
        reports.every(
          (request) =>
              (request.headers['Authorization'] as String).contains('secret'),
        ),
        isTrue,
      );
    },
  );

  test('inspect rejects non-Jellyfin and unsupported servers', () async {
    for (final data in [
      <String, dynamic>{},
      {'Id': 'server', 'Version': '10.9.0'},
    ]) {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: data,
              ),
            ),
          ),
        );
      final gateway = DioJellyfinGateway(dio: dio);
      if (data.isEmpty) {
        expect(
          () => gateway.inspectServer(Uri.parse('https://example.com')),
          throwsStateError,
        );
      } else {
        expect(
          () => gateway.authenticate(
            baseUrl: Uri.parse('https://example.com'),
            username: 'u',
            password: 'p',
            deviceId: 'd',
            allowPrivateHttp: false,
          ),
          throwsStateError,
        );
      }
    }
  });
}

AuthSession _session() {
  return AuthSession(
    profile: ServerProfile(
      profileId: 'profile',
      serverId: 'server',
      baseUrl: Uri.parse('https://music.example.com'),
      name: 'Music',
      userId: 'user',
      username: 'listener',
      deviceId: 'device',
      serverVersion: '10.10.0',
    ),
    token: 'secret',
  );
}

extension on ServerProfile {
  ServerProfile copyWithPrivateHttp(bool allowPrivateHttp) {
    return ServerProfile(
      profileId: profileId,
      serverId: serverId,
      baseUrl: Uri.parse('http://192.168.1.2:8096'),
      name: name,
      userId: userId,
      username: username,
      deviceId: deviceId,
      serverVersion: serverVersion,
      allowPrivateHttp: allowPrivateHttp,
    );
  }
}
