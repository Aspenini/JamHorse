import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/data/pre_release_reset.dart';

void main() {
  test('pre-release reset cancels and deletes all local state once', () async {
    final root = await Directory.systemTemp.createTemp('jamhorse-reset-');
    addTearDown(() => root.delete(recursive: true));
    final support = Directory('${root.path}/support')..createSync();
    final documents = Directory('${root.path}/documents')..createSync();
    final downloads = Directory('${support.path}/downloads')..createSync();
    File('${downloads.path}/partial.flac').writeAsStringSync('partial');
    for (final suffix in ['', '-wal', '-shm']) {
      File('${documents.path}/jamhorse.sqlite$suffix').writeAsStringSync('db');
    }
    final calls = <String>[];

    final reset = await PreReleaseReset.run(
      storedEpoch: 0,
      cancelDownloads: () async => calls.add('downloads'),
      support: support,
      documents: documents,
      clearArtwork: () async => calls.add('artwork'),
      clearCredentials: () async => calls.add('credentials'),
      saveEpoch: () async => calls.add('epoch'),
    );

    expect(reset, isTrue);
    expect(calls, ['downloads', 'artwork', 'credentials', 'epoch']);
    expect(downloads.existsSync(), isFalse);
    expect(
      documents.listSync().whereType<File>().where(
        (file) => file.path.contains('jamhorse.sqlite'),
      ),
      isEmpty,
    );

    calls.clear();
    final skipped = await PreReleaseReset.run(
      storedEpoch: 2,
      cancelDownloads: () async => calls.add('downloads'),
      support: support,
      documents: documents,
      clearArtwork: () async => calls.add('artwork'),
      clearCredentials: () async => calls.add('credentials'),
      saveEpoch: () async => calls.add('epoch'),
    );
    expect(skipped, isFalse);
    expect(calls, isEmpty);
  });
}
