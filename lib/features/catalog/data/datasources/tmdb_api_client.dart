import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/season_episode.dart';

class TmdbApiClient {
  final ApiClient _apiClient;
  final String? _apiKey;

  TmdbApiClient({ApiClient? apiClient, String? apiKey})
      : _apiClient = apiClient ?? ApiClient(baseUrl: ApiConstants.tmdbBaseUrl),
        _apiKey = apiKey;

  Map<String, dynamic> _buildParams([Map<String, dynamic>? extra]) {
    final params = <String, dynamic>{
      'language': 'en-US',
    };
    final key = _apiKey;
    if (key != null && key.isNotEmpty) {
      params['api_key'] = key;
    }
    if (extra != null) {
      params.addAll(extra);
    }
    return params;
  }

  Options get _authHeaders {
    final key = _apiKey;
    if (key != null && key.length > 32) {
      // TMDB v4 Read Access Token
      return Options(headers: {'Authorization': 'Bearer $key'});
    }
    return Options();
  }

  Future<List<MediaItem>> getTrending({String timeWindow = 'day'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/trending/all/$timeWindow',
        queryParameters: _buildParams(),
        options: _authHeaders,
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

  Future<List<MediaItem>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/movie/popular',
        queryParameters: _buildParams({'page': page}),
        options: _authHeaders,
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

  Future<List<MediaItem>> getPopularSeries({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/tv/popular',
        queryParameters: _buildParams({'page': page}),
        options: _authHeaders,
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

  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/search/multi',
        queryParameters: _buildParams({'query': query, 'page': page}),
        options: _authHeaders,
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

  Future<MediaItem> getMediaDetails(int tmdbId, MediaType type) async {
    final endpoint = type == MediaType.movie ? '/movie/$tmdbId' : '/tv/$tmdbId';
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: _buildParams({'append_to_response': 'credits,external_ids'}),
        options: _authHeaders,
      );

      if (response.data != null) {
        return MediaItem.fromTmdbJson(response.data!, explicitType: type);
      }
      throw Exception('Empty detail response');
    } catch (_) {
      return _getFallbackDetails(tmdbId, type);
    }
  }

  Future<Season> getSeasonDetails(int seriesId, int seasonNumber) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/tv/$seriesId/season/$seasonNumber',
        queryParameters: _buildParams(),
        options: _authHeaders,
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

  // Curated fallback showcase data when offline or no API key is provided
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
    return _getSampleTrendingItems().where((m) => m.type == MediaType.movie).toList();
  }

  List<MediaItem> _getSampleSeries() {
    return _getSampleTrendingItems().where((m) => m.type == MediaType.series).toList();
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
