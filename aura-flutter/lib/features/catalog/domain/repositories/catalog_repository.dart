import '../entities/media_item.dart';
import '../entities/person_details.dart';
import '../entities/season_episode.dart';

abstract class CatalogRepository {
  /// Fetches trending movies and series combined for home hero carousel and feeds.
  Future<List<MediaItem>> getTrending({String timeWindow = 'day'});

  /// Fetches trending movies.
  Future<List<MediaItem>> getTrendingMovies({String timeWindow = 'day'});

  /// Fetches trending TV shows.
  Future<List<MediaItem>> getTrendingSeries({String timeWindow = 'day'});

  /// Fetches popular movies.
  Future<List<MediaItem>> getPopularMovies({int page = 1});

  /// Fetches popular TV shows.
  Future<List<MediaItem>> getPopularSeries({int page = 1});

  /// Fetches latest released movies.
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1});

  /// Fetches latest airing TV shows.
  Future<List<MediaItem>> getOnTheAirSeries({int page = 1});

  /// Fetches top international & Asian dramas.
  Future<List<MediaItem>> getInternationalHits({int page = 1});

  /// Searches media across movies and series.
  Future<List<MediaItem>> searchMedia(String query, {int page = 1});

  /// Gets complete details (credits, IMDb ID, seasons) for a media item.
  Future<MediaItem> getMediaDetails(int tmdbId, MediaType type);

  /// Gets detailed episode list for a specific season.
  Future<Season> getSeasonDetails(int tmdbSeriesId, int seasonNumber);

  /// Gets video trailers and teaser clips for a media item.
  Future<List<Map<String, dynamic>>> getVideos(int tmdbId, MediaType type);

  /// Gets detailed biography and filmography credits for a person/actor.
  Future<PersonDetails> getPersonDetails(int personId);
}
