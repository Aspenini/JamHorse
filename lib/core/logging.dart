import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

final appLog = Logger('JamHorse');

const _maxBufferedLines = 500;
final _recentLines = <String>[];

void configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final line =
        '${record.time.toIso8601String()} '
        '[${record.level.name}] ${record.loggerName}: '
        '${_redact(record.message)}';
    _recentLines.add(line);
    if (_recentLines.length > _maxBufferedLines) _recentLines.removeAt(0);
    Zone.current.print(line);
  });
}

/// Writes the buffered (already redacted) log lines to a file and returns
/// it, for the Settings "Export redacted diagnostics" action.
Future<File> exportDiagnostics() async {
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final file = File(
    '${Directory.systemTemp.path}/jamhorse-diagnostics-$stamp.log',
  );
  final header =
      'JamHorse diagnostics · exported $stamp\n'
      'Platform: ${Platform.operatingSystem} '
      '${Platform.operatingSystemVersion}\n'
      'Tokens, passwords, and API keys are redacted.\n\n';
  await file.writeAsString(header + _recentLines.join('\n'));
  return file;
}

String _redact(String value) {
  return value
      .replaceAll(RegExp(r'api_key=[^&\s]+', caseSensitive: false), 'api_key=…')
      .replaceAllMapped(
        RegExp(r'(token|password)["=: ]+[^,}\s]+', caseSensitive: false),
        (match) => '${match[1]}=…',
      );
}
