class TmdbGenreMapper {
  static const Map<int, String> _genreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
    // TV Series Genre IDs
    10759: 'Action & Adventure',
    10762: 'Kids',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
  };

  static List<String> getGenreNames(List<int>? ids) {
    if (ids == null || ids.isEmpty) return const [];
    return ids
        .map((id) => _genreMap[id])
        .whereType<String>()
        .take(3) // Keep top 2-3 to avoid layout overflow
        .toList();
  }

  static int? getGenreIdByName(String name) {
    final nameLower = name.trim().toLowerCase();
    for (final entry in _genreMap.entries) {
      if (entry.value.toLowerCase() == nameLower) {
        return entry.key;
      }
    }
    // Fallback search
    if (nameLower.contains('action')) {
      return 28;
    }
    if (nameLower.contains('sci-fi') || nameLower.contains('science')) {
      return 878;
    }
    if (nameLower.contains('comedy')) {
      return 35;
    }
    if (nameLower.contains('drama')) {
      return 18;
    }
    if (nameLower.contains('horror')) {
      return 27;
    }
    if (nameLower.contains('animation') || nameLower.contains('anime')) {
      return 16;
    }
    if (nameLower.contains('crime')) {
      return 80;
    }
    if (nameLower.contains('thriller')) {
      return 53;
    }
    return 28; // Default Action
  }
}
