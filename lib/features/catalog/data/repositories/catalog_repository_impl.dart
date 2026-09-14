import '../../domain/entities/media_item.dart';
import '../../domain/entities/season_episode.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/tmdb_api_client.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final TmdbApiClient _apiClient;

  CatalogRepositoryImpl({TmdbApiClient? apiClient})
      : _apiClient = apiClient ?? TmdbApiClient();

  @override
  Future<List<MediaItem>> getTrending({String timeWindow = 'day'}) {
    return _apiClient.getTrending(timeWindow: timeWindow);
  }

  @override
  Future<List<MediaItem>> getTrendingMovies({String timeWindow = 'day'}) {
    return _apiClient.getTrendingMovies(timeWindow: timeWindow);
  }

  @override
  Future<List<MediaItem>> getTrendingSeries({String timeWindow = 'day'}) {
    return _apiClient.getTrendingSeries(timeWindow: timeWindow);
  }

  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) {
    return _apiClient.getPopularMovies(page: page);
  }

  @override
  Future<List<MediaItem>> getPopularSeries({int page = 1}) {
    return _apiClient.getPopularSeries(page: page);
  }

  @override
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) {
    return _apiClient.searchMedia(query, page: page);
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
}
