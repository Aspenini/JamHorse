import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/core/logging.dart';

void main() {
  test('diagnostic redaction removes URL and header credentials', () {
    final redacted = redactForDiagnostics(
      'GET /Audio/1?api_key=abc&x=1 '
      'Authorization: Bearer token-value '
      'password="hunter2"',
    );

    expect(redacted, isNot(contains('abc')));
    expect(redacted, isNot(contains('token-value')));
    expect(redacted, isNot(contains('hunter2')));
    expect(redacted, contains('api_key=…'));
    expect(redacted, contains('Authorization: …'));
  });

  test('diagnostic redaction is case insensitive', () {
    final redacted = redactForDiagnostics(
      'X-Emby-Token=SECRET CREDENTIALS: hidden',
    );

    expect(redacted, isNot(contains('SECRET')));
    expect(redacted, isNot(contains('hidden')));
  });

  test('exported diagnostics contain redacted buffered messages', () async {
    configureLogging();
    appLog.info('access_token=never-export-this');
    await Future<void>.delayed(Duration.zero);

    final file = await exportDiagnostics();
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });
    final contents = await File(file.path).readAsString();

    expect(contents, contains('access_token=…'));
    expect(contents, isNot(contains('never-export-this')));
    expect(contents, contains('Platform:'));
  });
}
