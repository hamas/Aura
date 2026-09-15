import 'package:dio/dio.dart';
import '../../../../core/config/env.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/person_details.dart';
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
      final items = results
          .whereType<Map<String, dynamic>>()
          .where((m) => m['media_type'] == 'movie' || m['media_type'] == 'tv')
          .map((m) => MediaItem.fromTmdbJson(m))
          .where((m) => m.isReleased)
          .toList();

      // Fetch clearart logos in parallel for hero billboard presentation
      final itemsWithLogos = await Future.wait(
        items.map((item) async {
          final logoPath = await fetchLogoPath(item.id, item.type);
          return logoPath != null ? item.copyWith(logoPath: logoPath) : item;
        }),
      );

      return itemsWithLogos;
    } catch (_) {
      return _getSampleTrendingItems().where((m) => m.isReleased).toList();
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
      final items = results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.movie))
          .where((m) => m.isReleased)
          .toList();

      final itemsWithLogos = await Future.wait(
        items.map((item) async {
          final logoPath = await fetchLogoPath(item.id, item.type);
          return logoPath != null ? item.copyWith(logoPath: logoPath) : item;
        }),
      );

      return itemsWithLogos;
    } catch (_) {
      return _getSampleMovies().where((m) => m.isReleased).toList();
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
      final items = results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.series))
          .where((m) => m.isReleased)
          .toList();

      final itemsWithLogos = await Future.wait(
        items.map((item) async {
          final logoPath = await fetchLogoPath(item.id, item.type);
          return logoPath != null ? item.copyWith(logoPath: logoPath) : item;
        }),
      );

      return itemsWithLogos;
    } catch (_) {
      return _getSampleSeries().where((m) => m.isReleased).toList();
    }
  }

  /// Fetches now playing / latest released movies
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/movie/now_playing',
        queryParameters: _buildParams({'page': page}),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.movie))
          .where((m) => m.isReleased)
          .toList();
    } catch (_) {
      return _getSampleMovies().where((m) => m.isReleased).toList();
    }
  }

  /// Fetches on the air / latest airing TV series
  Future<List<MediaItem>> getOnTheAirSeries({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/tv/on_the_air',
        queryParameters: _buildParams({'page': page}),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.series))
          .where((m) => m.isReleased)
          .toList();
    } catch (_) {
      return _getSampleSeries().where((m) => m.isReleased).toList();
    }
  }

  /// Discovers movies or TV series filtered by genre ID, sorted from latest releases to oldest
  Future<List<MediaItem>> discoverByGenre({
    required int genreId,
    required MediaType type,
    int page = 1,
    String? sortBy,
  }) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final endpoint =
        type == MediaType.movie ? '/discover/movie' : '/discover/tv';
    final sortParam = sortBy ??
        (type == MediaType.movie
            ? 'primary_release_date.desc'
            : 'first_air_date.desc');

    final extraParams = <String, dynamic>{
      'with_genres': genreId.toString(),
      'sort_by': sortParam,
      'page': page,
      'include_adult': 'false',
    };

    if (type == MediaType.movie) {
      extraParams['primary_release_date.lte'] = todayStr;
      extraParams['without_keywords'] = '9716,180547,190370,6075,10180,263548';
      extraParams['include_video'] = 'false';
      extraParams['vote_count.gte'] = '25';
    } else {
      extraParams['first_air_date.lte'] = todayStr;
      extraParams['without_genres'] = '10767,10763';
      extraParams['without_keywords'] = '9716,180547,190370,6075,10180';
      extraParams['vote_count.gte'] = '15';
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: _buildParams(extraParams),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: type))
          .where((m) => m.isReleased)
          .toList();
    } catch (_) {
      return (type == MediaType.movie ? _getSampleMovies() : _getSampleSeries())
          .where((m) => m.isReleased)
          .toList();
    }
  }

  /// Fetches popular movies (Prestige Hollywood & global mainstream)
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/discover/movie',
        queryParameters: _buildParams({
          'page': page,
          'sort_by': 'popularity.desc',
          'without_keywords': '9716,180547,190370,6075,10180,263548',
          'include_adult': 'false',
          'include_video': 'false',
          'vote_count.gte': '250',
          'vote_average.gte': '6.0',
          'with_original_language': 'en',
        }),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.movie))
          .where((m) => m.isReleased)
          .toList();
    } catch (_) {
      return _getSampleMovies().where((m) => m.isReleased).toList();
    }
  }

  /// Fetches popular TV series (Prestige mainstream)
  Future<List<MediaItem>> getPopularSeries({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/discover/tv',
        queryParameters: _buildParams({
          'page': page,
          'sort_by': 'popularity.desc',
          'without_genres': '10767,10763',
          'without_keywords': '9716,180547,190370,6075,10180',
          'include_adult': 'false',
          'vote_count.gte': '100',
          'vote_average.gte': '6.0',
          'with_original_language': 'en',
        }),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.series))
          .where((m) => m.isReleased)
          .toList();
    } catch (_) {
      return _getSampleSeries().where((m) => m.isReleased).toList();
    }
  }

  /// Fetches top international & Asian dramas (Korean, Japanese, Spanish, French)
  Future<List<MediaItem>> getInternationalHits({int page = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/discover/tv',
        queryParameters: _buildParams({
          'page': page,
          'sort_by': 'popularity.desc',
          'with_original_language': 'ko|ja|es|fr',
          'without_genres': '10767,10763',
          'without_keywords': '9716,180547,190370,6075,10180',
          'include_adult': 'false',
          'vote_count.gte': '50',
          'vote_average.gte': '6.5',
        }),
      );

      final results = response.data?['results'] as List<dynamic>? ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map((m) => MediaItem.fromTmdbJson(m, explicitType: MediaType.series))
          .where((m) => m.isReleased)
          .toList();
    } catch (_) {
      return _getSampleSeries().where((m) => m.isReleased).toList();
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

  /// Fetches full media metadata with guaranteed external IDs and clearart logo
  Future<MediaItem> getMediaDetails(int tmdbId, MediaType type) async {
    final endpoint = type == MediaType.movie ? '/movie/$tmdbId' : '/tv/$tmdbId';
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: _buildParams({
          'append_to_response': 'credits,external_ids,images,videos',
          'include_image_language': 'en,null',
        }),
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

        // Guarantee clearart logo mapping by querying images endpoint if missing
        if (mediaItem.logoPath == null || mediaItem.logoPath!.isEmpty) {
          final logoPath = await fetchLogoPath(tmdbId, type);
          if (logoPath != null) {
            mediaItem = mediaItem.copyWith(logoPath: logoPath);
          }
        }

        return mediaItem;
      }
      throw Exception('Empty detail response');
    } catch (_) {
      return _getFallbackDetails(tmdbId, type);
    }
  }

  /// Fetches actor/person details and filmography combined credits
  Future<PersonDetails> getPersonDetails(int personId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/person/$personId',
        queryParameters: _buildParams({
          'append_to_response': 'combined_credits,images',
        }),
      );

      if (response.data != null) {
        return PersonDetails.fromTmdbJson(response.data!);
      }
      throw Exception('Empty person detail response');
    } catch (_) {
      return PersonDetails(
        id: personId,
        name: 'Cast Member',
        biography: 'No biography available.',
        knownForDepartment: 'Acting',
      );
    }
  }

  /// Dedicated resolver for /movie/{id}/images and /tv/{id}/images clearart logos
  Future<String?> fetchLogoPath(int id, MediaType type) async {
    final path =
        type == MediaType.movie ? '/movie/$id/images' : '/tv/$id/images';
    try {
      final res = await _apiClient.get<Map<String, dynamic>>(
        path,
        queryParameters: _buildParams({'include_image_language': 'en,null'}),
      );
      final logos = (res.data?['logos'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .toList();
      if (logos != null && logos.isNotEmpty) {
        final enLogo = logos.firstWhere(
          (l) => l['iso_639_1'] == 'en',
          orElse: () => logos.first,
        );
        return enLogo['file_path'] as String?;
      }
      return null;
    } catch (_) {
      return null;
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
        logoPath: '/jP13n3bM08Y558q2n37m54x8s9.png',
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
        logoPath: '/1s29Y7Z6x8A4n3m98z7q29v.png',
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
        logoPath: '/rAiYTsqzrxtvoUw8TEFeLqvAlOT.png',
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
        title: 'Media Details',
        overview:
            'Detailed overview for this media item is being loaded from the catalog service.',
        voteAverage: 7.5,
        releaseDate: '2024-01-01',
        type: type,
      ),
    );
  }
}
