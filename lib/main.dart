import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/app.dart';
import 'package:jamhorse/core/artwork_cache.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/data/database.dart';
import 'package:jamhorse/data/jellyfin_gateway.dart';
import 'package:jamhorse/data/pre_release_reset.dart';
import 'package:jamhorse/data/report_buffer.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/platform/discord_presence.dart';
import 'package:jamhorse/platform/window_decorations.dart';
import 'package:jamhorse/playback/jamhorse_audio_handler.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();
  await PreReleaseReset.runIfNeeded();
  final windowDecorationMode = await loadWindowDecorationMode();
  seedWindowDecorationMode(windowDecorationMode);
  seedDiscordPresenceEnabled(await loadDiscordPresenceEnabled());

  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(
      windows: Platform.isWindows,
      linux: Platform.isLinux,
    );
  }

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    final customDecorations =
        windowDecorationMode == WindowDecorationMode.custom;
    final options = WindowOptions(
      size: const Size(1240, 800),
      minimumSize: const Size(720, 620),
      center: true,
      backgroundColor: const Color(0xFF000000),
      title: 'JamHorse',
      titleBarStyle: customDecorations
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
      windowButtonVisibility: !customDecorations,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final database = AppDatabase();
  final packageInfo = await PackageInfo.fromPlatform();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'JamHorse',
    ], await rootBundle.loadString('LICENSE'));
    yield LicenseEntryWithLineBreaks(const [
      'JamHorse third-party dependencies',
    ], await rootBundle.loadString('THIRD_PARTY_NOTICES.md'));
  });
  // Playback reports survive offline stretches via the buffering wrapper.
  final gateway = ReportBufferingGateway(
    DioJellyfinGateway(appVersion: packageInfo.version),
    database,
  );

  // Plays a downloaded copy instead of streaming when one exists on disk.
  Future<String?> localSource(LibraryItem item) async {
    final path = await database.completedDownloadPath(item.profileId, item.id);
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  Future<Uri?> localArtwork(AuthSession session, LibraryItem item) async {
    final image = item.imageUrl;
    if (image == null ||
        image.scheme != session.profile.baseUrl.scheme ||
        image.host != session.profile.baseUrl.host ||
        image.port != session.profile.baseUrl.port ||
        item.profileId != session.profile.profileId) {
      return null;
    }
    final file = await ArtworkCache.manager.getSingleFile(
      image.toString(),
      key: '${item.profileId}:$image',
      headers: gateway.playbackHeaders(session),
    );
    return file.uri;
  }

  final JamHorseAudioHandler audioHandler;
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux) {
    audioHandler = await AudioService.init<JamHorseAudioHandler>(
      builder: () => JamHorseAudioHandler(
        gateway,
        localSourceResolver: localSource,
        artworkResolver: localArtwork,
        database: database,
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.jamhorse.app.playback',
        androidNotificationChannelName: 'Music playback',
        androidNotificationChannelDescription:
            'Playback controls for your Jellyfin music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } else {
    audioHandler = JamHorseAudioHandler(
      gateway,
      localSourceResolver: localSource,
      artworkResolver: localArtwork,
      database: database,
    );
  }
  await audioHandler.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        jellyfinGatewayProvider.overrideWithValue(gateway),
        playbackCoordinatorProvider.overrideWithValue(audioHandler),
      ],
      child: const JamHorseApp(),
    ),
  );
}
