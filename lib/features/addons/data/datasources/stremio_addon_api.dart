import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/addon_manifest.dart';
import '../../domain/entities/addon_stream.dart';
import '../../domain/entities/addon_subtitle.dart';

class StremioAddonApi {
  final ApiClient _apiClient;

  StremioAddonApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Sanitizes incoming deep-link or manual manifest URLs into valid HTTPS manifest endpoints.
  static String sanitizeManifestUrl(String inputUrl) {
    String clean = inputUrl.trim();
    if ((clean.startsWith('"') && clean.endsWith('"')) ||
        (clean.startsWith("'") && clean.endsWith("'"))) {
      clean = clean.substring(1, clean.length - 1).trim();
    }

    if (clean.startsWith('aura://addon/install')) {
      final uri = Uri.tryParse(clean);
      if (uri != null && uri.queryParameters.containsKey('url')) {
        clean = Uri.decodeComponent(uri.queryParameters['url']!);
      }
    }

    if (clean.startsWith('stremio://')) {
      clean = clean.replaceFirst('stremio://', 'https://');
    } else if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }

    if (!clean.endsWith('manifest.json')) {
      clean = clean.endsWith('/')
          ? '${clean}manifest.json'
          : '$clean/manifest.json';
    }

    return clean;
  }

  /// Fetches and parses a Stremio v3 manifest from URL.
  Future<AddonManifest> fetchManifest(String manifestUrl) async {
    final formattedUrl = sanitizeManifestUrl(manifestUrl);

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        formattedUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
          responseType: ResponseType.json,
        ),
      );

      if (response.data != null) {
        final manifest = AddonManifest.fromJson(
          response.data!,
          transportUrl: formattedUrl,
        );

        if (manifest.id.isEmpty || manifest.name.isEmpty) {
          throw const AddonProtocolException(
              'Invalid manifest: Missing id or name');
        }

        return manifest;
      }
      throw const AddonProtocolException('Empty manifest received');
    } catch (e) {
      throw AddonProtocolException('Failed to fetch addon manifest: $e');
    }
  }

  /// Queries stream endpoint for an add-on: `{baseUrl}/stream/{type}/{id}.json`
  /// Standardized format:
  /// - Movies: `GET {addon_base_url}/stream/movie/{imdb_id}.json`
  /// - Series: `GET {addon_base_url}/stream/series/{imdb_id}:{season}:{episode}.json`
  Future<List<AddonStream>> fetchStreams({
    required AddonManifest manifest,
    required String type,
    required String id,
  }) async {
    if (!manifest.supportsResource('stream') &&
        !manifest.supportsResource('streams')) {
      return [];
    }

    if (!manifest.supportsType(type)) {
      return [];
    }

    // Strip /manifest.json to obtain base transport URL
    final baseUrl =
        manifest.transportUrl.replaceAll(RegExp(r'/manifest\.json$'), '');
    final streamUrl = '$baseUrl/stream/$type/$id.json';

    try {
      final response = await _apiClient
          .get<Map<String, dynamic>>(
            streamUrl,
            options: Options(
              sendTimeout: const Duration(milliseconds: 3500),
              receiveTimeout: const Duration(milliseconds: 3500),
            ),
          )
          .timeout(const Duration(milliseconds: 3500));

      final streamsRaw = response.data?['streams'] as List<dynamic>? ?? [];
      return streamsRaw
          .whereType<Map<String, dynamic>>()
          .map((json) => AddonStream.fromJson(json, addonName: manifest.name))
          .toList();
    } catch (_) {
      // Individual add-on timeouts (3.5s) or errors fail gracefully
      // without blocking other add-on stream aggregations
      return [];
    }
  }

  /// Queries subtitle endpoint for an add-on: `{baseUrl}/subtitles/{type}/{id}.json`
  /// Standardized format:
  /// - Movies: `GET {addon_base_url}/subtitles/movie/{imdb_id}.json`
  /// - Series: `GET {addon_base_url}/subtitles/series/{imdb_id}:{season}:{episode}.json`
  Future<List<AddonSubtitle>> fetchSubtitles({
    required AddonManifest manifest,
    required String type,
    required String id,
  }) async {
    if (!manifest.supportsResource('subtitles') &&
        !manifest.supportsResource('subtitle')) {
      return [];
    }

    if (!manifest.supportsType(type)) {
      return [];
    }

    final baseUrl =
        manifest.transportUrl.replaceAll(RegExp(r'/manifest\.json$'), '');
    final subtitleUrl = '$baseUrl/subtitles/$type/$id.json';

    try {
      final response = await _apiClient
          .get<Map<String, dynamic>>(
            subtitleUrl,
            options: Options(
              sendTimeout: const Duration(milliseconds: 3500),
              receiveTimeout: const Duration(milliseconds: 3500),
            ),
          )
          .timeout(const Duration(milliseconds: 3500));

      final subsRaw = response.data?['subtitles'] as List<dynamic>? ?? [];
      return subsRaw
          .whereType<Map<String, dynamic>>()
          .map((json) => AddonSubtitle.fromJson(json))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
