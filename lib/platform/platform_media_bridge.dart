import 'dart:io';

import 'package:flutter/services.dart';
import 'package:jamhorse/domain/contracts.dart';
import 'package:jamhorse/domain/models.dart';

class NativePlatformMediaBridge implements PlatformMediaBridge {
  const NativePlatformMediaBridge();

  static const _channel = MethodChannel('com.jamhorse.app/media');

  @override
  PlatformCapabilities get capabilities => PlatformCapabilities(
    googleCast: Platform.isAndroid || Platform.isIOS,
    airPlay: Platform.isIOS || Platform.isMacOS,
    equalizer: Platform.isAndroid || Platform.isWindows || Platform.isLinux,
    automotive: Platform.isAndroid || Platform.isIOS,
    desktopMediaKeys:
        Platform.isMacOS || Platform.isWindows || Platform.isLinux,
  );

  @override
  Future<void> applyEqualizer(List<double> bands) async {
    if (!capabilities.equalizer) return;
    await _invoke('applyEqualizer', {'bands': bands});
  }

  @override
  Future<void> connectCastDevice(String deviceId) async {
    if (!capabilities.googleCast) return;
    await _invoke('connectCastDevice', {'deviceId': deviceId});
  }

  @override
  Future<void> showOutputPicker() async {
    if (!capabilities.airPlay && !capabilities.googleCast) return;
    await _invoke('showOutputPicker');
  }

  Future<void> _invoke(String method, [Map<String, Object?>? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // The Dart capability surface remains stable while individual native
      // integrations are compiled only for their supported platforms.
    }
  }
}
