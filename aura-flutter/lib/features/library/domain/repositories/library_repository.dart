import '../entities/library_item.dart';

abstract class LibraryRepository {
  /// Fetches items by category (watchlist, continueWatching, history).
  Future<List<LibraryItem>> getLibraryItems({LibraryCategory? category});

  /// Adds or updates item in the library.
  Future<void> saveLibraryItem(LibraryItem item);

  /// Updates playback progress (seconds, duration, episode) for continue watching.
  Future<void> updateWatchProgress({
    required String mediaId,
    required String title,
    required String? posterPath,
    required String? backdropPath,
    required String type,
    required int positionSeconds,
    required int durationSeconds,
    int? seasonNumber,
    int? episodeNumber,
  });

  /// Removes item from watchlist or history.
  Future<void> removeItem(String mediaId);

  /// Synchronizes local state with cloud sync backend.
  Future<void> syncWithCloud();
}
