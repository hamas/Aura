import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/debrid_account.dart';

class RealDebridApiClient {
  final ApiClient _apiClient;

  RealDebridApiClient({ApiClient? apiClient})
      : _apiClient =
            apiClient ?? ApiClient(baseUrl: ApiConstants.realDebridBaseUrl);

  Options _authOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<DebridAccount> getUserDetails(String token) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/user',
        options: _authOptions(token),
      );
      if (response.data != null) {
        return DebridAccount.fromJson(response.data!);
      }
      throw const DebridException('Empty response from Real-Debrid API');
    } catch (e) {
      if (e is DebridException) rethrow;
      throw DebridException('Failed to fetch Real-Debrid account: $e');
    }
  }

  Future<String> addMagnet(String token, String magnetOrHash) async {
    final magnet = magnetOrHash.startsWith('magnet:')
        ? magnetOrHash
        : 'magnet:?xt=urn:btih:$magnetOrHash';

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/torrents/addMagnet',
        data: FormData.fromMap({'magnet': magnet}),
        options: _authOptions(token),
      );

      final torrentId = response.data?['id'] as String?;
      if (torrentId == null) {
        throw const DebridException('Failed to add magnet to Real-Debrid');
      }
      return torrentId;
    } catch (e) {
      throw DebridException('Real-Debrid addMagnet error: $e');
    }
  }

  Future<void> selectFiles(String token, String torrentId,
      {String fileIds = 'all'}) async {
    try {
      await _apiClient.post<dynamic>(
        '/torrents/selectFiles/$torrentId',
        data: FormData.fromMap({'files': fileIds}),
        options: _authOptions(token),
      );
    } catch (e) {
      throw DebridException('Real-Debrid selectFiles error: $e');
    }
  }

  Future<Map<String, dynamic>> getTorrentInfo(
      String token, String torrentId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/torrents/info/$torrentId',
        options: _authOptions(token),
      );
      return response.data ?? {};
    } catch (e) {
      throw DebridException('Real-Debrid getTorrentInfo error: $e');
    }
  }

  Future<String> unrestrictLink(String token, String link) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/unrestrict/link',
        data: FormData.fromMap({'link': link}),
        options: _authOptions(token),
      );
      final downloadUrl = response.data?['download'] as String?;
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        return downloadUrl;
      }
      throw const DebridException('Failed to unrestrict link with Real-Debrid');
    } catch (e) {
      throw DebridException('Real-Debrid unrestrictLink error: $e');
    }
  }
}
