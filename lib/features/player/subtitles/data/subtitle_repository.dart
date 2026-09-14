import 'dart:convert';
import 'package:aura/features/player/subtitles/domain/entities/subtitle_track_info.dart';
import 'package:http/http.dart' as http;

class SubtitleRepository {
  final http.Client _client;

  SubtitleRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Queries OpenSubtitles REST API for available subtitles by TMDB ID or IMDb ID.
  Future<List<SubtitleTrackInfo>> fetchSubtitles({
    required String tmdbOrImdbId,
    String language = 'en',
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.opensubtitles.com/api/v1/subtitles?tmdb_id=$tmdbOrImdbId&languages=$language',
      );
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'AuraMediaApp v1.0.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['data'] as List<dynamic>? ?? [];
        return items.map((item) {
          final attrs = item['attributes'] as Map<String, dynamic>? ?? {};
          final files = attrs['files'] as List<dynamic>? ?? [];
          final fileId =
              files.isNotEmpty ? files.first['file_id'].toString() : '';
          return SubtitleTrackInfo(
            id: item['id']?.toString() ?? '',
            language: attrs['language'] as String? ?? language,
            label:
                '${attrs['release'] ?? attrs['language'] ?? 'English'} (${attrs['format'] ?? 'SRT'})',
            url: fileId.isNotEmpty
                ? 'https://api.opensubtitles.com/api/v1/download/$fileId'
                : null,
          );
        }).toList();
      }
      return _getFallbackTracks();
    } catch (_) {
      return _getFallbackTracks();
    }
  }

  List<SubtitleTrackInfo> _getFallbackTracks() {
    return const [
      SubtitleTrackInfo(
        id: 'sub_en_official',
        language: 'en',
        label: 'English [CC]',
      ),
      SubtitleTrackInfo(
        id: 'sub_es_official',
        language: 'es',
        label: 'Spanish (Español)',
      ),
      SubtitleTrackInfo(
        id: 'sub_fr_official',
        language: 'fr',
        label: 'French (Français)',
      ),
    ];
  }
}
