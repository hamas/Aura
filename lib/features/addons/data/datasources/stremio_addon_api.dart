import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/addon_manifest.dart';
import '../../domain/entities/addon_stream.dart';

class StremioAddonApi {
  final ApiClient _apiClient;

  StremioAddonApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches and parses a Stremio v3 manifest from URL.
  Future<AddonManifest> fetchManifest(String manifestUrl) async {
    String formattedUrl = manifestUrl.trim();
    if (!formattedUrl.endsWith('manifest.json')) {
      formattedUrl = formattedUrl.endsWith('/')
          ? '${formattedUrl}manifest.json'
          : '$formattedUrl/manifest.json';
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        formattedUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
        ),
      );

      if (response.data != null) {
        return AddonManifest.fromJson(response.data!, transportUrl: formattedUrl);
      }
      throw const AddonProtocolException('Empty manifest received');
    } catch (e) {
      throw AddonProtocolException('Failed to fetch addon manifest: $e');
    }
  }

  /// Queries stream endpoint for an add-on: `{baseUrl}/stream/{type}/{id}.json`
  Future<List<AddonStream>> fetchStreams({
    required AddonManifest manifest,
    required String type,
    required String id,
  }) async {
    if (!manifest.supportsResource('stream') && !manifest.supportsResource('streams')) {
      return [];
    }

    if (!manifest.supportsType(type)) {
      return [];
    }

    // Strip /manifest.json to get base transport URL
    final baseUrl = manifest.transportUrl.replaceAll(RegExp(r'/manifest\.json$'), '');
    final streamUrl = '$baseUrl/stream/$type/$id.json';

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        streamUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final streamsRaw = response.data?['streams'] as List<dynamic>? ?? [];
      return streamsRaw
          .whereType<Map<String, dynamic>>()
          .map((json) => AddonStream.fromJson(json, addonName: manifest.name))
          .toList();
    } catch (e) {
      // Individual add-on timeouts or errors shouldn't crash the aggregate resolver
      return [];
    }
  }
}
