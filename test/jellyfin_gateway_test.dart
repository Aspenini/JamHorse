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
      final requests = <RequestOptions>[];
      final gateway = DioJellyfinGateway(
        dio: _recordingDio(
          requests,
          respond: (_) => {
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
        appVersion: 'test',
      );

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

      final request = requests.single;
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
        requests.last.queryParameters['IncludeItemTypes'],
        'Playlist,MusicGenre,Folder',
      );
    },
  );

  test('artists and genres filter by credit rather than parent', () async {
    final requests = <RequestOptions>[];
    final gateway = DioJellyfinGateway(
      dio: _recordingDio(requests),
      appVersion: 'test',
    );

    await gateway.fetchLibraryPage(
      _session(),
      artistId: 'artist',
      sortBy: 'SortName',
    );
    await gateway.fetchLibraryPage(_session(), genreId: 'genre');

    final artist = requests.first.queryParameters;
    expect(artist['ArtistIds'], 'artist');
    expect(artist, isNot(contains('ParentId')));
    expect(artist['SortBy'], 'SortName');
    expect(artist['SortOrder'], 'Ascending');
    expect(artist['EnableImageTypes'], 'Primary');
    final genre = requests.last.queryParameters;
    expect(genre['GenreIds'], 'genre');
    // No sort keeps the server's natural (playlist) order.
    expect(genre, isNot(contains('SortBy')));
    expect(genre, isNot(contains('SortOrder')));
  });

  test('albums credit their album artist and keep the date added', () async {
    final gateway = DioJellyfinGateway(
      dio: _recordingDio(
        [],
        respond: (_) => {
          'Items': [
            {
              'Id': 'album',
              'Type': 'MusicAlbum',
              'Name': 'Record',
              'AlbumArtists': [
                {'Id': 'artist', 'Name': 'Band'},
              ],
              'DateCreated': '2024-05-01T10:00:00.0000000Z',
            },
          ],
        },
      ),
      appVersion: 'test',
    );

    final album = (await gateway.fetchLibraryPage(_session())).items.single;

    expect(album.artistId, 'artist');
    expect(album.dateCreated, DateTime.utc(2024, 5, 1, 10));
  });

  test('stream and download URLs never contain credentials', () {
    final gateway = DioJellyfinGateway(appVersion: 'test');
    final session = _session();

    final stream = gateway.streamUri(session, _track());
    final download = gateway.downloadUri(session, _track());
    final userImage = gateway.userImageUri(session);

    for (final uri in [stream, download, userImage]) {
      expect(uri.queryParameters, isNot(contains('api_key')));
      expect(uri.queryParameters.values, isNot(contains('secret')));
      expect(uri.userInfo, isEmpty);
    }
    expect(download.path, '/Audio/track/stream');
    expect(download.queryParameters['static'], 'true');
    expect(userImage.path, '/Users/user/Images/Primary');
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

    expect(() => gateway.streamUri(blocked, _track()), throwsFormatException);
  });

  test(
    'authentication and focused gateway endpoints use typed responses',
    () async {
      final requests = <RequestOptions>[];
      final gateway = DioJellyfinGateway(
        dio: _recordingDio(
          requests,
          respond: (options) => switch (options.path) {
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
          },
        ),
        appVersion: '0.9.0',
      );

      final session = await gateway.authenticate(
        baseUrl: Uri.parse('https://music.example.com'),
        username: 'listener',
        password: 'password',
        deviceId: 'device',
        allowPrivateHttp: false,
      );
      final recent = await gateway.fetchRecentlyPlayed(session);
      final lyrics = await gateway.fetchLyrics(session, 'track');

      expect(session.profile.serverId, 'server');
      expect(session.profile.profileId, isNotEmpty);
      expect(session.token, 'secret');
      expect(recent.single.name, 'Song');
      expect(recent.single.isFavorite, isTrue);
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

  test('playlists are created empty and filled in chunks', () async {
    final requests = <RequestOptions>[];
    final gateway = DioJellyfinGateway(
      dio: _recordingDio(requests, respond: (_) => {'Id': 'new-playlist'}),
      appVersion: 'test',
    );

    final playlist = await gateway.createPlaylist(_session(), 'Road trip');
    await gateway.addToPlaylist(_session(), playlist.id, [
      for (var i = 0; i < 150; i++) 'track-$i',
    ]);

    expect(playlist.id, 'new-playlist');
    expect(playlist.type, LibraryItemType.playlist);
    expect(playlist.profileId, 'profile');
    expect(requests.first.path, endsWith('/Playlists'));
    expect(requests.first.data, containsPair('Name', 'Road trip'));
    final adds = requests.skip(1).toList();
    expect(adds, hasLength(2));
    expect(adds.first.path, endsWith('/Playlists/new-playlist/Items'));
    expect(
      (adds.first.queryParameters['Ids'] as String).split(','),
      hasLength(100),
    );
    expect(
      (adds.last.queryParameters['Ids'] as String).split(','),
      hasLength(50),
    );
  });

  test(
    'favorites and playback reports use headers and explicit sessions',
    () async {
      final requests = <RequestOptions>[];
      final gateway = DioJellyfinGateway(
        dio: _recordingDio(requests),
        appVersion: 'test',
      );
      final session = _session();
      final item = _track();

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

  test('sign-in rejects non-Jellyfin and unsupported servers', () async {
    for (final data in [
      <String, dynamic>{},
      {'Id': 'server', 'Version': '10.9.0'},
    ]) {
      final gateway = DioJellyfinGateway(
        dio: _recordingDio([], respond: (_) => data),
      );
      await expectLater(
        gateway.authenticate(
          baseUrl: Uri.parse('https://example.com'),
          username: 'u',
          password: 'p',
          deviceId: 'd',
          allowPrivateHttp: false,
        ),
        throwsStateError,
      );
    }
  });
}

/// A Dio whose requests are captured in [requests] and answered locally.
Dio _recordingDio(
  List<RequestOptions> requests, {
  Object? Function(RequestOptions options)? respond,
}) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: respond?.call(options) ?? const {'Items': <Object>[]},
            ),
          );
        },
      ),
    );
}

LibraryItem _track() {
  return const LibraryItem(
    id: 'track',
    profileId: 'profile',
    serverId: 'server',
    type: LibraryItemType.track,
    name: 'Song',
  );
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
