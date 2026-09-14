import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/debrid_account.dart';
import '../../domain/repositories/debrid_repository.dart';
import '../datasources/real_debrid_api_client.dart';

class DebridRepositoryImpl implements DebridRepository {
  final RealDebridApiClient _apiClient;
  final SecureStorageService _secureStorage;

  DebridRepositoryImpl({
    RealDebridApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? RealDebridApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<bool> hasValidToken() async {
    final token = await _secureStorage.getRealDebridApiKey();
    return token != null && token.trim().isNotEmpty;
  }

  @override
  Future<void> saveApiToken(String token) async {
    await _secureStorage.saveRealDebridApiKey(token.trim());
  }

  @override
  Future<DebridAccount> getAccountDetails() async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null) {
      throw const DebridException('Real-Debrid API key is not configured.');
    }
    return _apiClient.getUserDetails(token);
  }

  @override
  Future<String> unrestrictMagnetOrHash(String magnetOrInfoHash, {int? fileIndex}) async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null) {
      throw const DebridException('Real-Debrid API token is required to unrestrict streams.');
    }

    // 1. Add magnet to Real-Debrid
    final torrentId = await _apiClient.addMagnet(token, magnetOrInfoHash);

    // 2. Select file(s)
    await _apiClient.selectFiles(token, torrentId, fileIds: fileIndex != null ? '$fileIndex' : 'all');

    // 3. Poll/Get torrent info for links
    final info = await _apiClient.getTorrentInfo(token, torrentId);
    final links = info['links'] as List<dynamic>?;

    if (links != null && links.isNotEmpty) {
      final downloadLink = links.first as String;
      // 4. Unrestrict link
      return _apiClient.unrestrictLink(token, downloadLink);
    }

    throw const DebridException('Real-Debrid could not resolve instant download links for this torrent.');
  }

  @override
  Future<void> removeToken() async {
    await _secureStorage.deleteRealDebridApiKey();
  }
}
