import '../entities/debrid_account.dart';
import 'debrid_provider.dart';

class PremiumizeProviderImpl implements DebridProvider {
  String? _apiKey;

  PremiumizeProviderImpl({String? apiKey}) : _apiKey = apiKey;

  @override
  DebridProviderType get providerType => DebridProviderType.premiumize;

  @override
  String get name => providerType.displayName;

  @override
  String get tag => providerType.tag;

  @override
  Future<bool> hasValidToken() async => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  Future<void> saveApiKey(String key) async {
    _apiKey = key.trim();
  }

  @override
  Future<void> removeApiKey() async {
    _apiKey = null;
  }

  @override
  Future<DebridAccount> getUserInfo() async {
    return DebridAccount(
      providerType: DebridProviderType.premiumize,
      username: 'Premiumize User',
      email: '',
      points: 1000,
      type: 'premium',
      expirationDate: DateTime.now().add(const Duration(days: 30)),
      trafficRemainingGb: 1000.0,
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
    return 'https://premiumize.me/stream/$magnetOrInfoHash';
  }
}

class TorBoxProviderImpl implements DebridProvider {
  String? _apiKey;

  TorBoxProviderImpl({String? apiKey}) : _apiKey = apiKey;

  @override
  DebridProviderType get providerType => DebridProviderType.torBox;

  @override
  String get name => providerType.displayName;

  @override
  String get tag => providerType.tag;

  @override
  Future<bool> hasValidToken() async => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  Future<void> saveApiKey(String key) async {
    _apiKey = key.trim();
  }

  @override
  Future<void> removeApiKey() async {
    _apiKey = null;
  }

  @override
  Future<DebridAccount> getUserInfo() async {
    return DebridAccount(
      providerType: DebridProviderType.torBox,
      username: 'TorBox User',
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
    return 'https://torbox.app/stream/$magnetOrInfoHash';
  }
}
