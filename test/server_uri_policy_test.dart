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

    test('rejects embedded credentials and token-like query parameters', () {
      for (final input in [
        'https://user:secret@music.example.com',
        'https://music.example.com?api_key=secret',
        'https://music.example.com/#token',
      ]) {
        expect(() => ServerUriPolicy.normalize(input), throwsFormatException);
      }
    });

    test('does not treat local DNS names as private HTTP', () {
      expect(
        () => ServerUriPolicy.validate(
          Uri.parse('http://jellyfin.local:8096'),
          allowPrivateHttp: true,
        ),
        throwsFormatException,
      );
    });

    test('recognizes loopback, link-local, RFC1918, and ULA literals', () {
      for (final input in [
        'http://127.0.0.1:8096',
        'http://169.254.10.2:8096',
        'http://10.0.0.1:8096',
        'http://172.31.0.1:8096',
        'http://192.168.0.1:8096',
        'http://[fd00::1]:8096',
      ]) {
        expect(ServerUriPolicy.isPrivateHttp(Uri.parse(input)), isTrue);
      }
    });
  });
}
