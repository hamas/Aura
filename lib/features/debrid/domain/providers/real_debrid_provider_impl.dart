import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/real_debrid_api_client.dart';
import '../entities/debrid_account.dart';
import 'debrid_provider.dart';

class RealDebridProviderImpl implements DebridProvider {
  final RealDebridApiClient _apiClient;
  final SecureStorageService _secureStorage;

  RealDebridProviderImpl({
    RealDebridApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? RealDebridApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  @override
  DebridProviderType get providerType => DebridProviderType.realDebrid;

  @override
  String get name => providerType.displayName;

  @override
  String get tag => providerType.tag;

  @override
  Future<bool> hasValidToken() async {
    final token = await _secureStorage.getRealDebridApiKey();
    return token != null && token.trim().isNotEmpty;
  }

  @override
  Future<void> saveApiKey(String key) async {
    await _secureStorage.saveRealDebridApiKey(key.trim());
  }

  @override
  Future<void> removeApiKey() async {
    await _secureStorage.deleteRealDebridApiKey();
  }

  @override
  Future<DebridAccount> getUserInfo() async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null) {
      throw const DebridException('Real-Debrid API key not set.');
    }
    final account = await _apiClient.getUserDetails(token);
    return DebridAccount(
      providerType: DebridProviderType.realDebrid,
      username: account.username,
      email: account.email,
      points: account.points,
      type: account.type,
      expirationDate: account.expirationDate,
    );
  }

  @override
  Future<Map<String, bool>> checkAvailability(List<String> infoHashes) async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null || infoHashes.isEmpty) {
      return {};
    }
    return _apiClient.checkInstantAvailability(token, infoHashes);
  }

  @override
  Future<String> unrestrictLink(String magnetOrInfoHash,
      {int? fileIndex}) async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null) {
      throw const DebridException('Real-Debrid API key not set.');
    }

    final torrentId = await _apiClient.addMagnet(token, magnetOrInfoHash);
    await _apiClient.selectFiles(token, torrentId,
        fileIds: fileIndex != null ? '$fileIndex' : 'all');
    final info = await _apiClient.getTorrentInfo(token, torrentId);
    final links = info['links'] as List<dynamic>?;

    if (links != null && links.isNotEmpty) {
      final downloadLink = links.first as String;
      return _apiClient.unrestrictLink(token, downloadLink);
    }
    throw const DebridException(
        'No downloadable links returned from Real-Debrid.');
  }
}
