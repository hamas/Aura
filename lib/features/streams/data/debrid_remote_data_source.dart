import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class DebridRemoteDataSource {
  static const _storageKey = 'real_debrid_api_key';
  final FlutterSecureStorage _storage;
  final http.Client _client;

  DebridRemoteDataSource({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: _storageKey, value: key.trim());
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _storageKey);
  }

  /// Checks if torrent hashes are instantly cached on Real-Debrid servers.
  Future<Map<String, bool>> checkInstantAvailability(
      List<String> infoHashes) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty || infoHashes.isEmpty) {
      return {for (var h in infoHashes) h: true};
    }

    try {
      final joinedHashes = infoHashes.join('/');
      final uri = Uri.parse(
        'https://api.real-debrid.com/rest/1.0/torrents/instantAvailability/$joinedHashes',
      );
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final resultMap = <String, bool>{};
        for (final hash in infoHashes) {
          final hashData = data[hash.toLowerCase()];
          final rdAvailable = hashData != null &&
              hashData is Map &&
              (hashData['rd'] as List?)?.isNotEmpty == true;
          resultMap[hash] = rdAvailable;
        }
        return resultMap;
      }
      return {for (var h in infoHashes) h: true};
    } catch (_) {
      return {for (var h in infoHashes) h: true};
    }
  }

  /// Unrestricts a cached hoster or torrent link into a high-speed direct CDN stream.
  Future<String> unrestrictLink(String originalUrl) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return originalUrl;

    try {
      final uri =
          Uri.parse('https://api.real-debrid.com/rest/1.0/unrestrict/link');
      final response = await _client.post(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
        body: {'link': originalUrl},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['download'] as String? ?? originalUrl;
      }
      return originalUrl;
    } catch (_) {
      return originalUrl;
    }
  }
}
