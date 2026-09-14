import '../../domain/entities/media_item.dart';
import '../../domain/entities/person_details.dart';
import '../../domain/entities/season_episode.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/services/media_content_filter.dart';
import '../datasources/tmdb_api_client.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final TmdbApiClient _apiClient;

  CatalogRepositoryImpl({TmdbApiClient? apiClient})
      : _apiClient = apiClient ?? TmdbApiClient();

  @override
  Future<List<MediaItem>> getTrending({String timeWindow = 'day'}) async {
    final items = await _apiClient.getTrending(timeWindow: timeWindow);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> getTrendingMovies({String timeWindow = 'day'}) async {
    final items = await _apiClient.getTrendingMovies(timeWindow: timeWindow);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> getTrendingSeries({String timeWindow = 'day'}) async {
    final items = await _apiClient.getTrendingSeries(timeWindow: timeWindow);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async {
    final items = await _apiClient.getPopularMovies(page: page);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> getPopularSeries({int page = 1}) async {
    final items = await _apiClient.getPopularSeries(page: page);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1}) async {
    final items = await _apiClient.getNowPlayingMovies(page: page);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> getOnTheAirSeries({int page = 1}) async {
    final items = await _apiClient.getOnTheAirSeries(page: page);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> getInternationalHits({int page = 1}) async {
    final items = await _apiClient.getInternationalHits(page: page);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async {
    final items = await _apiClient.searchMedia(query, page: page);
    return MediaContentFilter.sanitize(items);
  }

  @override
  Future<MediaItem> getMediaDetails(int tmdbId, MediaType type) {
    return _apiClient.getMediaDetails(tmdbId, type);
  }

  @override
  Future<Season> getSeasonDetails(int tmdbSeriesId, int seasonNumber) {
    return _apiClient.getSeasonDetails(tmdbSeriesId, seasonNumber);
  }

  @override
  Future<List<Map<String, dynamic>>> getVideos(int tmdbId, MediaType type) {
    return _apiClient.getVideos(tmdbId, type);
  }

  @override
  Future<PersonDetails> getPersonDetails(int personId) {
    return _apiClient.getPersonDetails(personId);
  }
}
