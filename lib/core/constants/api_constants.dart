class ApiConstants {
  ApiConstants._();

  // TMDB Endpoints
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/original';
  static const String tmdbPosterW500 = 'https://image.tmdb.org/t/p/w500';
  static const String tmdbBackdropW1280 = 'https://image.tmdb.org/t/p/w1280';

  // Stremio v3 Constants
  static const String stremioProtocolVersion = '1.0.0';
  static const String defaultCinemetaUrl = 'https://v3-cinemeta.strem.io/manifest.json';
  static const String defaultTorrentioUrl = 'https://torrentio.strem.fun/manifest.json';

  // Real-Debrid API Endpoints
  static const String realDebridBaseUrl = 'https://api.real-debrid.com/rest/1.0';

  // Supabase (Default Config Placeholders)
  static const String defaultSupabaseUrl = 'https://aura-media-sync.supabase.co';
  static const String defaultSupabaseAnonKey = 'public-anon-key-placeholder';
}
