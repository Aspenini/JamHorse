import 'package:flutter_test/flutter_test.dart';
import 'package:jamhorse/data/jellyfin_gateway.dart';

void main() {
  group('DioJellyfinGateway.isSupportedServerVersion', () {
    test('accepts 10.10 and newer', () {
      expect(DioJellyfinGateway.isSupportedServerVersion('10.10.3'), isTrue);
      expect(DioJellyfinGateway.isSupportedServerVersion('10.11.0'), isTrue);
      expect(DioJellyfinGateway.isSupportedServerVersion('11.0.0'), isTrue);
    });

    test('rejects versions older than 10.10', () {
      expect(DioJellyfinGateway.isSupportedServerVersion('10.9.11'), isFalse);
      expect(DioJellyfinGateway.isSupportedServerVersion('10.2.0'), isFalse);
      expect(DioJellyfinGateway.isSupportedServerVersion('9.11.0'), isFalse);
    });

    test('rejects unparseable versions', () {
      expect(DioJellyfinGateway.isSupportedServerVersion(''), isFalse);
      expect(DioJellyfinGateway.isSupportedServerVersion('unknown'), isFalse);
    });
  });
}
