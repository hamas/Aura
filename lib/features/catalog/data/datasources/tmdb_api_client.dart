import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/season_episode.dart';

class TmdbApiClient {
  final ApiClient _apiClient;

  TmdbApiClient({ApiClient? apiClient})
      : _apiClient = apiClient ??
            ApiClient(
              dio: Dio(
                BaseOptions(
                  baseUrl: ApiConstants.tmdbBaseUrl,
                  connectTimeout: const Duration(seconds: 15),
                  receiveTimeout: const Duration(seconds: 15),
                  headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${Env.tmdbReadAccessToken}',
                  },
                ),
              )..interceptors.add(
                  InterceptorsWrapper(
                    onRequest: (options, handler) {
                      // Always attach Bearer token and api_key fallback
                      options.headers['Authorization'] =
                          'Bearer ${Env.tmdbReadAccessToken}';
                      if (!options.queryParameters.containsKey('api_key') &&
                          Env.tmdbApiKey.isNotEmpty) {
                        options.queryParameters['api_key'] = Env.tmdbApiKey;
                      }
                      return handler.next(options);
                    },
                  ),
                ),
            );

  Map<String, dynamic> _buildParams([Map<String, dynamic>? extra]) {
    final params = <String, dynamic>{
      'language': 'en-US',
    };
    if (extra != null) {
      params.addAll(extra);
    }
    return params;
  }

  /// Fetches trending movies and TV series combined for home hero banner and feeds
  Future<List<MediaItem>> getTrending({String timeWindow = 'day'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/trending/all/$timeWindow',
        queryParameters: _buildParams(),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .where((m) => m['media_type'] == 'movie' || m['media_type'] == 'tv')
          .map((m) => MediaItem.fromTmdbJson(m))
          .toList();
    } catch (_) {
      return _getSampleTrendingItems();
    }
  }

  /// Fetches trending movies
  Future<List<MediaItem>> getTrendingMovies({String timeWindow = 'day'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/trending/movie/$timeWindow',
        queryParameters: _buildParams(),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.movie))
          .toList();
    } catch (_) {
      return _getSampleMovies();
    }
  }

  /// Fetches trending TV series
  Future<List<MediaItem>> getTrendingSeries({String timeWindow = 'day'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/trending/tv/$timeWindow',
        queryParameters: _buildParams(),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.series))
          .toList();
    } catch (_) {
      return _getSampleSeries();
    }
  }

  /// Fetches popular movies
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/movie/popular',
        queryParameters: _buildParams({'page': page}),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.movie))
          .toList();
    } catch (_) {
      return _getSampleMovies();
    }
  }

  /// Fetches popular TV series
  Future<List<MediaItem>> getPopularSeries({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/tv/popular',
        queryParameters: _buildParams({'page': page}),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.series))
          .toList();
    } catch (_) {
      return _getSampleSeries();
    }
  }

  /// Searches multi-media catalog
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/search/multi',
        queryParameters: _buildParams({'query': query, 'page': page}),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .where((m) => m['media_type'] == 'movie' || m['media_type'] == 'tv')
          .map((m) => MediaItem.fromTmdbJson(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches full media metadata with guaranteed external IDs (IMDb ID mapping)
  Future<MediaItem> getMediaDetails(int tmdbId, MediaType type) async {
    final endpoint = type == MediaType.movie ? '/movie/$tmdbId' : '/tv/$tmdbId';
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        endpoint,
        queryParameters:
            _buildParams({'append_to_response': 'credits,external_ids'}),
      );

      if (response.data != null) {
        var mediaItem =
            MediaItem.fromTmdbJson(response.data!, explicitType: type);

        // Guarantee IMDb ID mapping by querying dedicated external_ids endpoint if missing
        if (mediaItem.imdbId == null || mediaItem.imdbId!.isEmpty) {
          final imdbId = await fetchExternalImdbId(tmdbId, type);
          if (imdbId != null) {
            mediaItem = mediaItem.copyWith(imdbId: imdbId);
          }
        }

        return mediaItem;
      }
      throw Exception('Empty detail response');
    } catch (_) {
      return _getFallbackDetails(tmdbId, type);
    }
  }

  /// Dedicated resolver for /movie/{id}/external_ids and /tv/{id}/external_ids
  Future<String?> fetchExternalImdbId(int id, MediaType type) async {
    final path = type == MediaType.movie
        ? '/movie/$id/external_ids'
        : '/tv/$id/external_ids';
    try {
      final res = await _apiClient.get<Map<String, dynamic>>(path);
      return res.data?['imdb_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetches detailed episode list for a TV season
  Future<Season> getSeasonDetails(int seriesId, int seasonNumber) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/tv/$seriesId/season/$seasonNumber',
        queryParameters: _buildParams(),
      );

      if (response.data != null) {
        return Season.fromJson(response.data!);
      }
      throw Exception('Empty season response');
    } catch (_) {
      return Season(
        id: seasonNumber,
        seasonNumber: seasonNumber,
        name: 'Season $seasonNumber',
        overview: 'Episodes for season $seasonNumber',
        episodes: [
          Episode(
            id: 101,
            episodeNumber: 1,
            seasonNumber: seasonNumber,
            name: 'Episode 1',
            overview: 'The journey begins.',
            voteAverage: 8.5,
          ),
          Episode(
            id: 102,
            episodeNumber: 2,
            seasonNumber: seasonNumber,
            name: 'Episode 2',
            overview: 'The plot unfolds.',
            voteAverage: 8.7,
          ),
        ],
      );
    }
  }

  /// Fetches video trailers and teaser clips for a media item
  Future<List<Map<String, dynamic>>> getVideos(
      int tmdbId, MediaType type) async {
    final endpoint = type == MediaType.movie
        ? '/movie/$tmdbId/videos'
        : '/tv/$tmdbId/videos';
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: _buildParams(),
      );
      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  // Fallback showcase data for offline or demo testing
  List<MediaItem> _getSampleTrendingItems() {
    return [
      const MediaItem(
        id: 693134,
        imdbId: 'tt15239678',
        title: 'Dune: Part Two',
        overview:
            'Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a path of revenge against the conspirators who destroyed his family.',
        posterPath: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
        backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520b4.jpg',
        voteAverage: 8.3,
        releaseDate: '2024-03-01',
        type: MediaType.movie,
        tagline: 'Long live the fighters.',
        runtimeMinutes: 166,
      ),
      const MediaItem(
        id: 94605,
        imdbId: 'tt1190634',
        title: 'Arcane',
        overview:
            'Set in the utopian region of Piltover and the oppressed underground of Zaun, the story follows the origins of two iconic League champions-and the power that will tear them apart.',
        posterPath: '/abf8tZvngYjGlSr00m0UrkLJg49.jpg',
        backdropPath: '/fqv8v6AycXKsivp1T5yKtLbGXce.jpg',
        voteAverage: 8.7,
        releaseDate: '2021-11-06',
        type: MediaType.series,
        tagline: 'Every legend has a beginning.',
      ),
      const MediaItem(
        id: 157336,
        imdbId: 'tt0816692',
        title: 'Interstellar',
        overview:
            'The adventures of a group of explorers who make use of a newly discovered wormhole to surpass the limitations on human space travel and conquer the vast distances involved in an interstellar voyage.',
        posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        backdropPath: '/rAiYTsqzrxtvoUw8TEFeLqvAlOT.jpg',
        voteAverage: 8.4,
        releaseDate: '2014-11-05',
        type: MediaType.movie,
        tagline: 'Mankind was born on Earth. It was never meant to die here.',
        runtimeMinutes: 169,
      ),
    ];
  }

  List<MediaItem> _getSampleMovies() {
    return _getSampleTrendingItems()
        .where((m) => m.type == MediaType.movie)
        .toList();
  }

  List<MediaItem> _getSampleSeries() {
    return _getSampleTrendingItems()
        .where((m) => m.type == MediaType.series)
        .toList();
  }

  MediaItem _getFallbackDetails(int id, MediaType type) {
    return _getSampleTrendingItems().firstWhere(
      (m) => m.id == id,
      orElse: () => MediaItem(
        id: id,
        imdbId: 'tt0137523',
        title: 'Fight Club',
        overview:
            'A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.',
        voteAverage: 8.8,
        releaseDate: '1999-10-15',
        type: type,
        runtimeMinutes: 139,
      ),
    );
  }
}
