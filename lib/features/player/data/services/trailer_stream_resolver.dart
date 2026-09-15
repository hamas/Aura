import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum TrailerSource { youtubeDirect, itunes, trakt, none }

class TrailerStreamResult {
  final String? streamUrl;
  final TrailerSource source;
  final String? title;

  const TrailerStreamResult({
    this.streamUrl,
    required this.source,
    this.title,
  });

  bool get hasStream => streamUrl != null && streamUrl!.isNotEmpty;
}

/// Pure Dart multi-tiered trailer stream resolution pipeline for Aura.
class TrailerStreamResolver {
  final http.Client _httpClient;

  TrailerStreamResolver({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Attempts to resolve a direct playable stream URL across YouTube, iTunes, and Trakt.
  Future<TrailerStreamResult> resolveTrailerStream({
    required String title,
    String? year,
    String? tmdbTrailerUrl,
    String? mediaType,
  }) async {
    // Tier 1: YouTube Direct Stream Extraction via YoutubeExplode
    if (tmdbTrailerUrl != null && tmdbTrailerUrl.isNotEmpty) {
      final videoId = YoutubeExplodeUtil.extractVideoId(tmdbTrailerUrl);
      if (videoId != null && videoId.isNotEmpty) {
        final ytResult = await _resolveYouTubeDirectStream(videoId);
        if (ytResult.hasStream) return ytResult;
      }
    }

    // Tier 2: iTunes Search API Fallback
    final itunesResult = await _resolveITunesPreviewStream(
      title: title,
      year: year,
      mediaType: mediaType,
    );
    if (itunesResult.hasStream) return itunesResult;

    // Tier 3: Trakt API Fallback
    final traktResult = await _resolveTraktTrailerStream(
      title: title,
      year: year,
    );
    if (traktResult.hasStream) return traktResult;

    return const TrailerStreamResult(source: TrailerSource.none);
  }

  Future<TrailerStreamResult> _resolveYouTubeDirectStream(String videoId) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 5));

      // Prioritize Muxed (video + audio in single stream) or MP4 video streams
      final muxedStreams = manifest.muxed.sortByVideoQuality();
      if (muxedStreams.isNotEmpty) {
        final optimal = muxedStreams.firstWhere(
          (s) => s.container.name == 'mp4',
          orElse: () => muxedStreams.first,
        );
        return TrailerStreamResult(
          streamUrl: optimal.url.toString(),
          source: TrailerSource.youtubeDirect,
        );
      }

      // If no muxed stream, grab highest quality video stream
      final videoStreams = manifest.videoOnly.sortByVideoQuality();
      if (videoStreams.isNotEmpty) {
        return TrailerStreamResult(
          streamUrl: videoStreams.first.url.toString(),
          source: TrailerSource.youtubeDirect,
        );
      }
    } catch (_) {
      // Fall through gracefully on timeout, age-restriction, or private video exception
    } finally {
      yt.close();
    }
    return const TrailerStreamResult(source: TrailerSource.none);
  }

  Future<TrailerStreamResult> _resolveITunesPreviewStream({
    required String title,
    String? year,
    String? mediaType,
  }) async {
    try {
      final entity = (mediaType == 'series' || mediaType == 'tv')
          ? 'tvShow'
          : 'movie';
      final encodedTitle = Uri.encodeComponent(title);
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=$encodedTitle&entity=$entity&limit=5');

      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        for (final item in results) {
          if (item is Map<String, dynamic>) {
            final previewUrl = item['previewUrl'] as String?;
            if (previewUrl != null && previewUrl.isNotEmpty) {
              final trackName =
                  (item['trackName'] ?? item['collectionName'] ?? '') as String;
              final releaseDate = (item['releaseDate'] ?? '') as String;

              if (year != null && year.isNotEmpty && releaseDate.length >= 4) {
                if (!releaseDate.startsWith(year)) {
                  continue;
                }
              }
              return TrailerStreamResult(
                streamUrl: previewUrl,
                source: TrailerSource.itunes,
                title: trackName,
              );
            }
          }
        }
        // Fallback: Return first previewUrl if year filter was strict
        for (final item in results) {
          if (item is Map<String, dynamic> && item['previewUrl'] != null) {
            return TrailerStreamResult(
              streamUrl: item['previewUrl'] as String,
              source: TrailerSource.itunes,
              title: item['trackName'] as String?,
            );
          }
        }
      }
    } catch (_) {
      // Fall through gracefully
    }
    return const TrailerStreamResult(source: TrailerSource.none);
  }

  Future<TrailerStreamResult> _resolveTraktTrailerStream({
    required String title,
    String? year,
  }) async {
    // Tertiary fallback reserved for Trakt community trailer stream resolution
    return const TrailerStreamResult(source: TrailerSource.none);
  }
}

class YoutubeExplodeUtil {
  static String? extractVideoId(String url) {
    if (url.length == 11 && !url.contains('/') && !url.contains('?')) {
      return url;
    }
    final regExp = RegExp(
      r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }
}
