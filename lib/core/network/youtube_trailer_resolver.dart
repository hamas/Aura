import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeTrailerResolver {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, String> _cache = {};

  /// Extracts YouTube video ID from full URL or returns raw key
  static String? extractVideoKey(String urlOrKey) {
    if (urlOrKey.isEmpty) return null;
    if (!urlOrKey.contains('http') && !urlOrKey.contains('.')) {
      return urlOrKey.trim();
    }
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(urlOrKey);
    return match?.group(1);
  }

  /// Resolves YouTube video key to a direct MP4/HLS Googlevideo stream URL via YoutubeExplode
  static Future<String?> resolveDirectStreamUrl(String urlOrKey) async {
    final videoKey = extractVideoKey(urlOrKey);
    if (videoKey == null || videoKey.isEmpty) return null;

    if (_cache.containsKey(videoKey)) {
      return _cache[videoKey];
    }

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoKey);

      // 1. Try muxed streams (video + audio combined)
      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.withHighestBitrate();
        final url = muxedStream.url.toString();
        _cache[videoKey] = url;
        return url;
      }

      // 2. Fallback to video-only streams (ideal for muted background hero trailers)
      if (manifest.videoOnly.isNotEmpty) {
        final videoOnlyStream = manifest.videoOnly.withHighestBitrate();
        final url = videoOnlyStream.url.toString();
        _cache[videoKey] = url;
        return url;
      }
    } catch (_) {
      // Return null on failure to allow static backdrop fallback
    }

    return null;
  }
}
