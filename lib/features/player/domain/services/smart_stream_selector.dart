import '../../../addons/domain/entities/addon_stream.dart';

/// Configuration options for the autonomous Smart Play stream scoring engine.
class SmartStreamOptions {
  final String maxResolution; // '4K', '1080p', '720p'
  final bool preferHevc;
  final double? maxFileSizeGB;
  final bool dataSaverMode;

  const SmartStreamOptions({
    this.maxResolution = '4K',
    this.preferHevc = true,
    this.maxFileSizeGB = 30.0,
    this.dataSaverMode = false,
  });
}

/// Heuristic scoring and ranking engine for selecting the optimal stream.
class SmartStreamSelector {
  const SmartStreamSelector();

  /// Calculates a heuristic score for an [AddonStream].
  ///
  /// Heuristics applied:
  /// - Direct HTTP / HLS Stream (`isDirectHttp == true` -> +1000 pts).
  /// - Resolution Matching: 4K (+500), 1080p (+300), 720p (+100). Respects [options.maxResolution].
  /// - Codec & Efficiency: HEVC / AV1 / H.265 (+200 pts).
  /// - Audio Fidelity: Spatial audio / Multichannel (Atmos / 5.1 / 7.1) (+100 pts).
  /// - File Size Safety: Penalizes excessive file sizes (> 30GB -> -200 pts) and low-bitrate rips (< 1GB for 1080p/4K -> -100 pts).
  int scoreStream(
    AddonStream stream, {
    SmartStreamOptions options = const SmartStreamOptions(),
  }) {
    int score = 0;

    // 1. Direct Stream Status (+1000 pts)
    if (stream.isDirectHttp) {
      score += 1000;
    } else if (stream.isCached) {
      score += 800;
    } else {
      score -= 500;
    }

    // 2. Resolution Matching
    final res = stream.resolution.toLowerCase();
    final targetMax = options.maxResolution.toLowerCase();

    if (targetMax.contains('4k')) {
      if (res.contains('4k') || res.contains('2160p') || res.contains('uhd')) {
        score += 500;
      } else if (res.contains('1080p')) {
        score += 300;
      } else if (res.contains('720p')) {
        score += 100;
      }
    } else if (targetMax.contains('1080p')) {
      if (res.contains('1080p')) {
        score += 500;
      } else if (res.contains('720p')) {
        score += 300;
      } else if (res.contains('4k') || res.contains('2160p')) {
        score += options.dataSaverMode ? -100 : 200;
      }
    } else {
      if (res.contains('720p')) {
        score += 500;
      } else if (res.contains('480p') || res.contains('sd')) {
        score += 300;
      }
    }

    // 3. Codec & Efficiency (+200 pts)
    if (stream.isHevc) {
      score += options.preferHevc ? 200 : 100;
    }

    // 4. Audio Fidelity (+100 pts)
    if (stream.hasSpatialAudio) {
      score += 100;
    }

    // 5. File Size Safety & Quality Bitrate Thresholds
    final size = stream.fileSizeGB;
    if (size != null) {
      if (options.maxFileSizeGB != null && size > options.maxFileSizeGB!) {
        score -= 200;
      }
      if ((res.contains('1080p') || res.contains('4k')) && size < 1.0) {
        score -= 100;
      }
    }

    return score;
  }

  /// Selects the best stream from a list.
  /// Returns null if [streams] is empty or no streams are available.
  AddonStream? selectBestStream(
    List<AddonStream> streams, {
    SmartStreamOptions options = const SmartStreamOptions(),
  }) {
    if (streams.isEmpty) return null;
    final ranked = rankStreams(streams, options: options);
    return ranked.isEmpty ? null : ranked.first;
  }

  /// Returns streams sorted by score in descending order.
  List<AddonStream> rankStreams(
    List<AddonStream> streams, {
    SmartStreamOptions options = const SmartStreamOptions(),
  }) {
    final list = List<AddonStream>.from(streams);
    list.sort((a, b) {
      final scoreA = scoreStream(a, options: options);
      final scoreB = scoreStream(b, options: options);
      return scoreB.compareTo(scoreA);
    });
    return list;
  }
}
