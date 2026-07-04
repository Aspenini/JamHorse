import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';

class NativePlatformMediaBridge implements PlatformMediaBridge {
  NativePlatformMediaBridge();

  static const _channel = MethodChannel('com.jamhorse.app/media');
  static const _castAppId = String.fromEnvironment('CAST_RECEIVER_APP_ID');

  final _capabilityController =
      StreamController<PlatformCapabilities>.broadcast();
  final _targetController = StreamController<List<CastTarget>>.broadcast();
  final _remoteController = StreamController<RemotePlaybackState>.broadcast();
  final _castDevices = <String, GoogleCastDevice>{};
  final _subscriptions = <StreamSubscription<dynamic>>[];

  PlatformCapabilities _capabilities = const PlatformCapabilities(
    googleCast: false,
    airPlay: false,
    equalizer: false,
    automotive: false,
    desktopMediaKeys: false,
  );
  bool _initialized = false;
  RemotePlaybackState _remoteSession = const RemotePlaybackState();

  @override
  PlatformCapabilities get capabilities => _capabilities;

  @override
  Stream<PlatformCapabilities> get capabilityChanges =>
      _capabilityController.stream;

  @override
  Stream<List<CastTarget>> get castTargets => _targetController.stream;

  @override
  RemotePlaybackState get remoteSession => _remoteSession;

  @override
  Stream<RemotePlaybackState> get remoteSessionChanges =>
      _remoteController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    var native = const <String, dynamic>{};
    try {
      native =
          await _channel.invokeMapMethod<String, dynamic>('getCapabilities') ??
          const {};
    } on MissingPluginException {
      // Capabilities remain false when the native implementation is absent.
    }

    final castConfigured =
        _castAppId.isNotEmpty && (Platform.isAndroid || Platform.isIOS);
    _capabilities = PlatformCapabilities(
      googleCast: castConfigured,
      airPlay: native['airPlay'] == true,
      equalizer: native['equalizer'] == true,
      automotive: native['automotive'] == true,
      desktopMediaKeys:
          native['desktopMediaKeys'] == true ||
          Platform.isWindows ||
          Platform.isLinux,
    );
    _emitCapabilities();

    if (!castConfigured) return;
    final options = Platform.isIOS
        ? IOSGoogleCastOptions(
            GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
              _castAppId,
            ),
            disableAnalyticsLogging: true,
          )
        : GoogleCastOptionsAndroid(appId: _castAppId);
    final ready = await GoogleCastContext.instance.setSharedInstanceWithOptions(
      options,
    );
    if (!ready) {
      _capabilities = _copyCapabilities(googleCast: false);
      _emitCapabilities();
      return;
    }

    _subscriptions
      ..add(
        GoogleCastDiscoveryManager.instance.devicesStream.listen((devices) {
          _castDevices
            ..clear()
            ..addEntries(
              devices.map((device) => MapEntry(device.deviceID, device)),
            );
          _targetController.add(
            devices
                .map(
                  (device) => CastTarget(
                    id: device.deviceID,
                    name: device.friendlyName,
                    model: device.modelName,
                  ),
                )
                .toList(growable: false),
          );
        }),
      )
      ..add(
        GoogleCastSessionManager.instance.currentSessionStream.listen((
          session,
        ) {
          _capabilities = _copyCapabilities(castConnected: session != null);
          _remoteSession = RemotePlaybackState(
            connected: session != null,
            position: _remoteSession.position,
            playing: session == null ? false : _remoteSession.playing,
            buffering: session == null ? false : _remoteSession.buffering,
            itemId: session == null ? null : _remoteSession.itemId,
          );
          _emitCapabilities();
          _emitRemoteSession();
        }),
      )
      ..add(
        GoogleCastRemoteMediaClient.instance.mediaStatusStream.listen((status) {
          _remoteSession = RemotePlaybackState(
            connected: _capabilities.castConnected,
            playing: status?.playerState == CastMediaPlayerState.playing,
            buffering:
                status?.playerState == CastMediaPlayerState.buffering ||
                status?.playerState == CastMediaPlayerState.loading,
            position: _remoteSession.position,
            itemId: status?.mediaInformation?.contentId,
          );
          _emitRemoteSession();
        }),
      )
      ..add(
        GoogleCastRemoteMediaClient.instance.playerPositionStream.listen((
          position,
        ) {
          _remoteSession = RemotePlaybackState(
            connected: _capabilities.castConnected,
            playing: _remoteSession.playing,
            buffering: _remoteSession.buffering,
            position: position,
            itemId: _remoteSession.itemId,
          );
          _emitRemoteSession();
        }),
      );
    await GoogleCastDiscoveryManager.instance.startDiscovery();
  }

  @override
  Future<void> connectCastDevice(
    String deviceId,
    AuthSession session,
    PlaybackSnapshot snapshot,
    JellyfinGateway gateway,
  ) async {
    if (!_capabilities.googleCast) {
      throw StateError('Google Cast is not configured for this build.');
    }
    if (session.profile.baseUrl.scheme != 'https') {
      throw StateError('Google Cast requires an HTTPS Jellyfin server.');
    }
    final device = _castDevices[deviceId];
    if (device == null) {
      throw StateError('The Cast device is no longer available.');
    }
    final connected = await GoogleCastSessionManager.instance
        .startSessionWithDevice(device);
    if (!connected) {
      throw StateError('Could not connect to the Cast device.');
    }

    final authHeaders = gateway.playbackHeaders(session);
    if (snapshot.queue.items.isEmpty || snapshot.queue.currentIndex < 0) {
      throw StateError('There is no active queue to transfer.');
    }
    final queue = snapshot.queue.items
        .map((item) {
          final stream = gateway
              .streamUri(session, item)
              .replace(
                queryParameters: {
                  ...gateway.streamUri(session, item).queryParameters,
                  'TranscodingProtocol': 'hls',
                  'TranscodingContainer': 'ts',
                  'SegmentContainer': 'ts',
                },
              );
          return GoogleCastQueueItem(
            mediaInformation: GoogleCastMediaInformation(
              contentId: item.id,
              contentUrl: stream,
              contentType: 'application/x-mpegURL',
              streamType: CastMediaStreamType.buffered,
              duration: item.duration,
              customData: {'headers': authHeaders, 'profileId': item.profileId},
              metadata: GoogleCastMusicMediaMetadata(
                title: item.name,
                artist: item.artists.isEmpty
                    ? item.subtitle
                    : item.artists.join(', '),
                albumName: item.albumName,
                trackNumber: item.indexNumber,
                discNumber: item.discNumber,
              ),
            ),
          );
        })
        .toList(growable: false);
    await GoogleCastRemoteMediaClient.instance.queueLoadItems(
      queue,
      options: GoogleCastQueueLoadOptions(
        startIndex: snapshot.queue.currentIndex.clamp(0, queue.length - 1),
        playPosition: snapshot.position,
        repeatMode: switch (snapshot.queue.repeatMode) {
          RepeatMode.off => GoogleCastMediaRepeatMode.off,
          RepeatMode.all => GoogleCastMediaRepeatMode.all,
          RepeatMode.one => GoogleCastMediaRepeatMode.single,
        },
      ),
    );
  }

  @override
  Future<void> disconnectCast() {
    return GoogleCastSessionManager.instance.endSessionAndStopCasting();
  }

  @override
  Future<void> remotePlay() => GoogleCastRemoteMediaClient.instance.play();

  @override
  Future<void> remotePause() => GoogleCastRemoteMediaClient.instance.pause();

  @override
  Future<void> remoteSeek(Duration position) {
    return GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: position,
        resumeState: GoogleCastMediaResumeState.unchanged,
      ),
    );
  }

  @override
  Future<void> remoteNext() =>
      GoogleCastRemoteMediaClient.instance.queueNextItem();

  @override
  Future<void> remotePrevious() =>
      GoogleCastRemoteMediaClient.instance.queuePrevItem();

  @override
  Future<void> showEqualizer({int? audioSessionId}) {
    return _invoke('showEqualizer', {'audioSessionId': audioSessionId});
  }

  @override
  Future<void> showOutputPicker() => _invoke('showOutputPicker');

  Future<void> _invoke(String method, [Map<String, Object?>? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      throw UnsupportedError('$method is not available on this platform.');
    }
  }

  PlatformCapabilities _copyCapabilities({
    bool? googleCast,
    bool? castConnected,
  }) {
    return PlatformCapabilities(
      googleCast: googleCast ?? _capabilities.googleCast,
      airPlay: _capabilities.airPlay,
      equalizer: _capabilities.equalizer,
      automotive: _capabilities.automotive,
      desktopMediaKeys: _capabilities.desktopMediaKeys,
      castConnected: castConnected ?? _capabilities.castConnected,
    );
  }

  void _emitCapabilities() {
    if (!_capabilityController.isClosed) {
      _capabilityController.add(_capabilities);
    }
  }

  void _emitRemoteSession() {
    if (!_remoteController.isClosed) {
      _remoteController.add(_remoteSession);
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _capabilityController.close();
    await _targetController.close();
    await _remoteController.close();
  }
}
