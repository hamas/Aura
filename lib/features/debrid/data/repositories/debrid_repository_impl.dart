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
  Future<String> unrestrictMagnetOrHash(String magnetOrInfoHash,
      {int? fileIndex}) async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null) {
      throw const DebridException(
          'Real-Debrid API token is required to unrestrict streams.');
    }

    if (magnetOrInfoHash.startsWith('http://') ||
        magnetOrInfoHash.startsWith('https://')) {
      return _apiClient.unrestrictLink(token, magnetOrInfoHash);
    }

    // 1. Add magnet to Real-Debrid
    final torrentId = await _apiClient.addMagnet(token, magnetOrInfoHash);

    // 2. Select file(s)
    await _apiClient.selectFiles(token, torrentId,
        fileIds: fileIndex != null ? '$fileIndex' : 'all');

    // 3. Poll/Get torrent info for links with retry loop (15 attempts x 600ms = 9s total)
    Map<String, dynamic> info = {};
    List<dynamic>? links;
    for (int i = 0; i < 15; i++) {
      info = await _apiClient.getTorrentInfo(token, torrentId);
      links = info['links'] as List<dynamic>?;
      if (links != null && links.isNotEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (links != null && links.isNotEmpty) {
      String downloadLink = links.first as String;
      if (fileIndex != null) {
        if (fileIndex > 0 && fileIndex <= links.length) {
          downloadLink = links[fileIndex - 1] as String;
        } else if (fileIndex >= 0 && fileIndex < links.length) {
          downloadLink = links[fileIndex] as String;
        }
      }
      // 4. Unrestrict link
      return _apiClient.unrestrictLink(token, downloadLink);
    }

    throw const DebridException(
        'Real-Debrid could not resolve instant download links for this torrent.');
  }

  @override
  Future<String> unrestrictLink(String link) async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null) {
      throw const DebridException(
          'Real-Debrid API token is required to unrestrict streams.');
    }
    return _apiClient.unrestrictLink(token, link);
  }

  @override
  Future<void> removeToken() async {
    await _secureStorage.deleteRealDebridApiKey();
  }
}
