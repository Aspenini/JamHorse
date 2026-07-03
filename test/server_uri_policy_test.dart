import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/core/server_uri_policy.dart';

void main() {
  group('ServerUriPolicy', () {
    test('adds HTTPS to host-only input', () {
      expect(
        ServerUriPolicy.normalize('music.example.com').toString(),
        'https://music.example.com',
      );
    });

    test('allows explicitly trusted private HTTP', () {
      expect(
        () => ServerUriPolicy.validate(
          Uri.parse('http://192.168.1.12:8096'),
          allowPrivateHttp: true,
        ),
        returnsNormally,
      );
    });

    test('rejects public HTTP', () {
      expect(
        () => ServerUriPolicy.validate(
          Uri.parse('http://music.example.com'),
          allowPrivateHttp: true,
        ),
        throwsFormatException,
      );
    });
  });
}
