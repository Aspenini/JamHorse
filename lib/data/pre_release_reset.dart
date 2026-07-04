import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jamhorse/core/artwork_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreReleaseReset {
  const PreReleaseReset._();

  static const _epoch = 2;
  static const _preferenceKey = 'storageSchemaEpoch';

  static Future<bool> runIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();
    final downloader = FileDownloader();
    return run(
      storedEpoch: preferences.getInt(_preferenceKey) ?? 0,
      cancelDownloads: () async {
        await downloader.start();
        await downloader.cancelAll();
      },
      support: await getApplicationSupportDirectory(),
      documents: await getApplicationDocumentsDirectory(),
      clearArtwork: ArtworkCache.clear,
      clearCredentials: () => const FlutterSecureStorage(
        mOptions: MacOsOptions(usesDataProtectionKeychain: false),
      ).deleteAll(),
      saveEpoch: () => preferences.setInt(_preferenceKey, _epoch),
    );
  }

  static Future<bool> run({
    required int storedEpoch,
    required Future<void> Function() cancelDownloads,
    required Directory support,
    required Directory documents,
    required Future<void> Function() clearArtwork,
    required Future<void> Function() clearCredentials,
    required Future<void> Function() saveEpoch,
  }) async {
    if (storedEpoch >= _epoch) return false;

    await cancelDownloads();
    final downloads = Directory(
      '${support.path}${Platform.pathSeparator}downloads',
    );
    if (await downloads.exists()) {
      await downloads.delete(recursive: true);
    }
    for (final suffix in ['', '-wal', '-shm']) {
      final database = File(
        '${documents.path}${Platform.pathSeparator}jamhorse.sqlite$suffix',
      );
      if (await database.exists()) await database.delete();
    }
    await clearArtwork();
    await clearCredentials();
    await saveEpoch();
    return true;
  }
}
