import '../entities/media_item.dart';

/// Sanitization service that filters out non-narrative media content such as
/// stand-up comedy specials, stage plays, concerts, talk shows, and news.
class MediaContentFilter {
  static const List<String> _blacklistedTitlePhrases = [
    'stand-up',
    'stand up',
    'live at',
    'comedy special',
    'in concert',
    'tour live',
    'broadway',
    'the musical live',
    'the roast of',
  ];

  /// Evaluates whether a [MediaItem] represents a legitimate narrative movie or series.
  static bool isLegitimateNarrative(MediaItem item) {
    final titleLower = item.title.toLowerCase();

    // 1. Check title indicators for blacklisted non-narrative phrases
    for (final phrase in _blacklistedTitlePhrases) {
      if (titleLower.contains(phrase)) return false;
    }

    // 2. Reject non-narrative genre combinations (Talk shows: 10767, News: 10763)
    if (item.genreIds.contains(10767) || item.genreIds.contains(10763)) {
      return false;
    }

    return true;
  }

  /// Filters a list of [MediaItem] to contain only legitimate narrative media.
  static List<MediaItem> sanitize(List<MediaItem> items) {
    return items.where(isLegitimateNarrative).toList();
  }
}
