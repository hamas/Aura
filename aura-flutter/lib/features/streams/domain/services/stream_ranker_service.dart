import 'package:aura/features/streams/domain/entities/scraped_stream_item.dart';

class StreamRankerService {
  /// Ranks scraped streams based on resolution, HDR/Dolby Vision, file size, seeders, and cached state.
  static List<ScrapedStreamItem> rankStreams(
    List<ScrapedStreamItem> streams, {
    bool requireCachedOnly = false,
  }) {
    final filtered = requireCachedOnly
        ? streams.where((s) => s.isCached).toList()
        : List<ScrapedStreamItem>.from(streams);

    filtered.sort((a, b) {
      final scoreA = _calculateScore(a);
      final scoreB = _calculateScore(b);
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  static double _calculateScore(ScrapedStreamItem item) {
    double score = 0.0;

    // 1. Resolution Score
    final resLower = item.resolution.toLowerCase();
    if (resLower.contains('4k') || resLower.contains('2160p')) {
      score += 400.0;
    } else if (resLower.contains('1080p')) {
      score += 250.0;
    } else if (resLower.contains('720p')) {
      score += 100.0;
    }

    // 2. High Dynamic Range & Audio Codec Bonus
    if (item.isDolbyVision) score += 150.0;
    if (item.isHdr) score += 100.0;
    if (item.isDolbyAtmos) score += 80.0;
    if (item.isDtsHd) score += 60.0;
    if (item.isRemux) score += 120.0;

    // 3. File Size Bonus (Optimal 5GB to 25GB)
    if (item.sizeGb > 0) {
      if (item.sizeGb >= 5.0 && item.sizeGb <= 30.0) {
        score += item.sizeGb * 2.5;
      } else {
        score += item.sizeGb;
      }
    }

    // 4. Seeders Weight
    score += (item.seeders * 0.5).clamp(0.0, 100.0);

    // 5. Cached Penalty/Bonus
    if (item.isCached) {
      score += 200.0;
    }

    return score;
  }
}
