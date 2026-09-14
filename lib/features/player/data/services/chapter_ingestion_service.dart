import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/media_interval.dart';

class ChapterIngestionService {
  final http.Client _client;

  ChapterIngestionService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetches intro, recap, and credit timestamps for a media item.
  /// First attempts external Intro-Skipper API, then falls back to default heuristics.
  Future<List<MediaInterval>> fetchIntervals({
    required String imdbId,
    int? season,
    int? episode,
    Duration? videoDuration,
  }) async {
    final intervals = <MediaInterval>[];

    try {
      // 1. Query external Intro-Skipper / Skip API if episode context is available
      if (imdbId.startsWith('tt') && season != null && episode != null) {
        final uri = Uri.parse(
            'https://api.intro-skipper.org/v1/skip/$imdbId/s${season}e$episode');
        final response =
            await _client.get(uri).timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            if (data['intro'] != null) {
              final startSec = (data['intro']['start'] as num).toDouble();
              final endSec = (data['intro']['end'] as num).toDouble();
              intervals.add(MediaInterval(
                type: MediaIntervalType.intro,
                start: Duration(milliseconds: (startSec * 1000).round()),
                end: Duration(milliseconds: (endSec * 1000).round()),
              ));
            }

            if (data['recap'] != null) {
              final startSec = (data['recap']['start'] as num).toDouble();
              final endSec = (data['recap']['end'] as num).toDouble();
              intervals.add(MediaInterval(
                type: MediaIntervalType.recap,
                start: Duration(milliseconds: (startSec * 1000).round()),
                end: Duration(milliseconds: (endSec * 1000).round()),
              ));
            }

            if (data['credits'] != null) {
              final startSec = (data['credits']['start'] as num).toDouble();
              final endSec = (data['credits']['end'] as num).toDouble();
              intervals.add(MediaInterval(
                type: MediaIntervalType.credits,
                start: Duration(milliseconds: (startSec * 1000).round()),
                end: videoDuration ??
                    Duration(milliseconds: ((endSec + 120) * 1000).round()),
              ));
            }
          }
        }
      }
    } catch (_) {
      // Graceful fallback to default interval detection heuristics
    }

    // 2. Default heuristic fallback for TV episodes when API returns empty
    if (intervals.isEmpty && season != null && episode != null) {
      // Common TV Intro: 01:30 -> 03:00
      intervals.add(const MediaInterval(
        type: MediaIntervalType.intro,
        start: Duration(seconds: 90),
        end: Duration(seconds: 180),
      ));

      if (videoDuration != null && videoDuration.inSeconds > 300) {
        // Credits start 2.5 minutes before end of episode
        final creditsStart = videoDuration - const Duration(seconds: 150);
        intervals.add(MediaInterval(
          type: MediaIntervalType.credits,
          start: creditsStart,
          end: videoDuration,
        ));
      }
    }

    return intervals;
  }
}
