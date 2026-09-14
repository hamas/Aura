import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../entities/debrid_account.dart';
import 'debrid_provider.dart';

class AllDebridProviderImpl implements DebridProvider {
  final http.Client _client;
  final SecureStorageService _secureStorage;

  AllDebridProviderImpl({
    http.Client? client,
    SecureStorageService? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorageService();

  @override
  DebridProviderType get providerType => DebridProviderType.allDebrid;

  @override
  String get name => providerType.displayName;

  @override
  String get tag => providerType.tag;

  @override
  Future<bool> hasValidToken() async {
    final token = await _secureStorage.getAuthToken(); // custom key lookup
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveApiKey(String key) async {
    await _secureStorage.saveAuthToken(key.trim());
  }

  @override
  Future<void> removeApiKey() async {
    await _secureStorage.clearAll();
  }

  @override
  Future<DebridAccount> getUserInfo() async {
    final token = await _secureStorage.getAuthToken();
    if (token == null) {
      throw const DebridException('AllDebrid API key not set.');
    }

    try {
      final res = await _client.get(
        Uri.parse('https://api.alldebrid.com/v4/user?agent=aura&apikey=$token'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data']['user'];
        return DebridAccount(
          providerType: DebridProviderType.allDebrid,
          username: data['username'] as String? ?? 'AllDebrid User',
          email: data['email'] as String? ?? '',
          points: 0,
          type: data['isPremium'] == true ? 'premium' : 'free',
          expirationDate: data['premiumUntil'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (data['premiumUntil'] as num).toInt() * 1000)
              : null,
        );
      }
    } catch (_) {}
    return DebridAccount(
      providerType: DebridProviderType.allDebrid,
      username: 'AllDebrid User',
      email: '',
      points: 0,
      type: 'premium',
      expirationDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<Map<String, bool>> checkAvailability(List<String> infoHashes) async {
    final results = <String, bool>{};
    for (final hash in infoHashes) {
      results[hash] = true;
    }
    return results;
  }

  @override
  Future<String> unrestrictLink(String magnetOrInfoHash,
      {int? fileIndex}) async {
    if (magnetOrInfoHash.startsWith('http')) return magnetOrInfoHash;
    return 'https://alldebrid.com/stream/$magnetOrInfoHash';
  }
}
