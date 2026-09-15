import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum TrailerSource { youtubeDirect, itunes, youtubeEmbed, trakt, none }

class TrailerStreamResult {
  final String? streamUrl;
  final TrailerSource source;
  final String? title;
  final String? embedUrl;

  const TrailerStreamResult({
    this.streamUrl,
    required this.source,
    this.title,
    this.embedUrl,
  });

  bool get hasStream => (streamUrl != null && streamUrl!.isNotEmpty) || (embedUrl != null && embedUrl!.isNotEmpty);
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
    final videoId = tmdbTrailerUrl != null ? YoutubeExplodeUtil.extractVideoId(tmdbTrailerUrl) : null;
    debugPrint('[TrailerResolver] Resolving for: $title (${year ?? "N/A"}), TMDB key: ${videoId ?? "N/A"}');

    // Run YouTube Direct extraction and iTunes Search in parallel for fastest time-to-first-frame
    final ytFuture = (videoId != null && videoId.isNotEmpty)
        ? _resolveYouTubeDirectStream(videoId)
        : Future.value(const TrailerStreamResult(source: TrailerSource.none));

    final itunesFuture = _resolveITunesPreviewStream(
      title: title,
      year: year,
      mediaType: mediaType,
    );

    // Race YouTube extraction with 2.5 second hard cap against iTunes
    try {
      final ytResult = await ytFuture.timeout(const Duration(milliseconds: 2500));
      if (ytResult.hasStream) {
        debugPrint('[TrailerResolver] Tier 1 Success (YouTube Direct): ${ytResult.streamUrl}');
        return ytResult;
      }
    } catch (e) {
      debugPrint('[TrailerResolver] Tier 1 Timeout/Error (YouTube Direct): $e');
    }

    // Tier 2: Check iTunes Search Result
    try {
      final itunesResult = await itunesFuture;
      if (itunesResult.hasStream) {
        debugPrint('[TrailerResolver] Tier 2 Success (iTunes Direct MP4): ${itunesResult.streamUrl}');
        return itunesResult;
      }
    } catch (e) {
      debugPrint('[TrailerResolver] Tier 2 Exception (iTunes): $e');
    }

    // Tier 3: Privacy-enhanced clean Youtube embed fallback URL when direct scrapers are 403-blocked
    if (videoId != null && videoId.isNotEmpty) {
      final cleanEmbedUrl =
          'https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&controls=0&modestbranding=1&rel=0&iv_load_policy=3&playsinline=1&mute=1';
      debugPrint('[TrailerResolver] Tier 3 Fallback (Clean YouTube Embed): $cleanEmbedUrl');
      return TrailerStreamResult(
        embedUrl: cleanEmbedUrl,
        source: TrailerSource.youtubeEmbed,
        title: title,
      );
    }

    debugPrint('[TrailerResolver] All resolution tiers exhausted. Triggering AmbientBackdropFallback.');
    return const TrailerStreamResult(source: TrailerSource.none);
  }

  Future<TrailerStreamResult> _resolveYouTubeDirectStream(String videoId) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(milliseconds: 2500));

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
    } catch (e) {
      debugPrint('[TrailerResolver] YoutubeExplode error for ID $videoId: $e');
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
    final sanitizedTitle = _sanitizeTitle(title);
    final entity = (mediaType == 'series' || mediaType == 'tv') ? 'tvShow' : 'movie';

    final result = await _executeITunesSearch(
      searchQuery: sanitizedTitle,
      entity: entity,
      year: year,
    );

    if (result.hasStream) return result;

    // Retry once with primary title before colon/dash if full title returned no results
    if (sanitizedTitle.contains(':') || sanitizedTitle.contains(' - ')) {
      final primaryTitle = sanitizedTitle.split(RegExp(r'[:\-]')).first.trim();
      if (primaryTitle.isNotEmpty && primaryTitle != sanitizedTitle) {
        debugPrint('[TrailerResolver] Retrying iTunes Search with primary title: $primaryTitle');
        final retryResult = await _executeITunesSearch(
          searchQuery: primaryTitle,
          entity: entity,
          year: year,
        );
        if (retryResult.hasStream) return retryResult;
      }
    }

    return const TrailerStreamResult(source: TrailerSource.none);
  }

  Future<TrailerStreamResult> _executeITunesSearch({
    required String searchQuery,
    required String entity,
    String? year,
  }) async {
    try {
      final encodedTitle = Uri.encodeComponent(searchQuery);
      final uri = Uri.parse(
          'https://itunes.apple.com/search?term=$encodedTitle&entity=$entity&limit=5');

      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 4));
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
    } catch (e) {
      debugPrint('[TrailerResolver] iTunes Search HTTP error: $e');
    }
    return const TrailerStreamResult(source: TrailerSource.none);
  }

  String _sanitizeTitle(String title) {
    // Remove year brackets/parentheses e.g., (2024) or [2024]
    var cleaned = title.replaceAll(RegExp(r'\s*[\(\[\{]\d{4}[\)\]\}]'), '');
    // Replace special punctuation while preserving letters, numbers, spaces, colons, hyphens
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s\:\-]'), '');
    return cleaned.trim();
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
