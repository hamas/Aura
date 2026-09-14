import '../entities/debrid_account.dart';

abstract class DebridProvider {
  DebridProviderType get providerType;
  String get name;
  String get tag;

  Future<bool> hasValidToken();
  Future<void> saveApiKey(String key);
  Future<void> removeApiKey();
  Future<DebridAccount> getUserInfo();
  Future<Map<String, bool>> checkAvailability(List<String> infoHashes);
  Future<String> unrestrictLink(String magnetOrInfoHash, {int? fileIndex});
}
