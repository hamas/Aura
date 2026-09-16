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

    try {
      if (magnetOrInfoHash.startsWith('http://') ||
          magnetOrInfoHash.startsWith('https://')) {
        return await _apiClient.unrestrictLink(token, magnetOrInfoHash);
      }

      // 1. Add magnet to Real-Debrid
      final torrentId = await _apiClient.addMagnet(token, magnetOrInfoHash);

      // 2. Select file(s)
      await _apiClient.selectFiles(token, torrentId,
          fileIds: fileIndex != null ? '$fileIndex' : 'all');

      // 3. Poll/Get torrent info for links with retry loop and instant uncached detection
      Map<String, dynamic> info = {};
      List<dynamic>? links;
      for (int i = 0; i < 8; i++) {
        info = await _apiClient.getTorrentInfo(token, torrentId);
        final status = (info['status'] as String?)?.toLowerCase();

        // If status indicates the file is not instantly cached on Real-Debrid, fail fast
        if (status == 'downloading' ||
            status == 'queued' ||
            status == 'compressing' ||
            status == 'magnet_conversion' ||
            status == 'waiting_files_selection') {
          throw const DebridException(
              'This file is not cached on Real-Debrid yet. Please select an [RD+] instant stream.');
        } else if (status == 'dead' || status == 'error' || status == 'virus') {
          throw const DebridException(
              'Torrent is dead or returned an error on Real-Debrid.');
        }

        links = info['links'] as List<dynamic>?;
        if (links != null && links.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
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
        return await _apiClient.unrestrictLink(token, downloadLink);
      }

      throw const DebridException(
          'Real-Debrid could not resolve instant download links for this torrent.');
    } catch (e) {
      if (e.toString().contains('permission_denied') || e.toString().contains('error_code: 9')) {
        await _secureStorage.deleteRealDebridApiKey();
        throw const DebridException(
            'Your Real-Debrid subscription or token has expired. Please update your token in Settings.');
      }
      rethrow;
    }
  }

  @override
  Future<String> unrestrictLink(String link) async {
    final token = await _secureStorage.getRealDebridApiKey();
    if (token == null) {
      throw const DebridException(
          'Real-Debrid API token is required to unrestrict streams.');
    }
    try {
      return await _apiClient.unrestrictLink(token, link);
    } catch (e) {
      if (e.toString().contains('permission_denied') || e.toString().contains('error_code: 9')) {
        await _secureStorage.deleteRealDebridApiKey();
        throw const DebridException(
            'Your Real-Debrid subscription or token has expired. Please update your token in Settings.');
      }
      rethrow;
    }
  }

  @override
  Future<void> removeToken() async {
    await _secureStorage.deleteRealDebridApiKey();
  }
}
