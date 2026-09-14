import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyRealDebridApiKey = 'rd_api_key';
  static const String _keyUserAuthToken = 'user_auth_token';

  Future<void> saveRealDebridApiKey(String key) async {
    await _storage.write(key: _keyRealDebridApiKey, value: key);
  }

  Future<String?> getRealDebridApiKey() async {
    return _storage.read(key: _keyRealDebridApiKey);
  }

  Future<void> deleteRealDebridApiKey() async {
    await _storage.delete(key: _keyRealDebridApiKey);
  }

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyUserAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return _storage.read(key: _keyUserAuthToken);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
