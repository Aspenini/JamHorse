import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jamhorse/domain/contracts.dart';

class SecureCredentialStore implements CredentialStore {
  const SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // The data-protection keychain requires a signed
            // keychain-access-groups entitlement, which ad-hoc dev builds
            // don't have; the file-based keychain works either way.
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<void> deleteToken(String profileId) {
    return _storage.delete(key: _key(profileId));
  }

  @override
  Future<String?> readToken(String profileId) {
    return _storage.read(key: _key(profileId));
  }

  @override
  Future<void> writeToken(String profileId, String token) {
    return _storage.write(key: _key(profileId), value: token);
  }

  String _key(String profileId) => 'server.$profileId.accessToken';
}
