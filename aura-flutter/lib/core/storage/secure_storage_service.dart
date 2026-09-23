import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyUserAuthToken = 'user_auth_token';
  static const String _keyRealDebridApiKey = 'aura_real_debrid_api_key';
  static const String _keyTorBoxApiKey = 'aura_torbox_api_key';

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyUserAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return _storage.read(key: _keyUserAuthToken);
  }

  Future<void> saveRealDebridApiKey(String key) async {
    await _storage.write(key: _keyRealDebridApiKey, value: key.trim());
  }

  Future<String?> getRealDebridApiKey() async {
    return _storage.read(key: _keyRealDebridApiKey);
  }

  Future<void> saveTorBoxApiKey(String key) async {
    await _storage.write(key: _keyTorBoxApiKey, value: key.trim());
  }

  Future<String?> getTorBoxApiKey() async {
    return _storage.read(key: _keyTorBoxApiKey);
  }

  Future<void> clearDebridKeys() async {
    await _storage.delete(key: _keyRealDebridApiKey);
    await _storage.delete(key: _keyTorBoxApiKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
