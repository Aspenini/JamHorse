import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamhorse/app/app.dart';
import 'package:jamhorse/core/logging.dart';
import 'package:jamhorse/data/database.dart';
import 'package:jamhorse/data/jellyfin_gateway.dart';
import 'package:jamhorse/data/report_buffer.dart';
import 'package:jamhorse/domain/models.dart';
import 'package:jamhorse/playback/jamhorse_audio_handler.dart';
import 'package:jamhorse/state/providers.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();

  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized(
      windows: Platform.isWindows,
      linux: Platform.isLinux,
    );
  }

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1240, 800),
      minimumSize: Size(720, 620),
      center: true,
      backgroundColor: Color(0xFF070A14),
      title: 'JamHorse',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final database = AppDatabase();
  // Playback reports survive offline stretches via the buffering wrapper.
  final gateway = ReportBufferingGateway(DioJellyfinGateway(), database);

  // Plays a downloaded copy instead of streaming when one exists on disk.
  Future<String?> localSource(LibraryItem item) async {
    final path = await database.completedDownloadPath(
      item.serverId,
      item.id,
    );
    if (path == null || !File(path).existsSync()) return null;
    return path;
  }

  final JamHorseAudioHandler audioHandler;
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    audioHandler = await AudioService.init<JamHorseAudioHandler>(
      builder: () =>
          JamHorseAudioHandler(gateway, localSourceResolver: localSource),
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
