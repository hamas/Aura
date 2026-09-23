import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/library_item.dart';
import '../../domain/repositories/library_repository.dart';
import '../../../downloads/data/repositories/download_repository_impl.dart';
import '../datasources/cloud_sync_datasource.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final SharedPreferences _prefs;
  final CloudSyncDataSource _cloudSync;
  final AuthRepository? _authRepository;

  static const String _keyLocalLibrary = 'aura_local_library_v1';

  LibraryRepositoryImpl({
    required SharedPreferences prefs,
    CloudSyncDataSource? cloudSync,
    AuthRepository? authRepository,
  })  : _prefs = prefs,
        _cloudSync = cloudSync ?? CloudSyncDataSource(),
        _authRepository = authRepository;

  Future<String> _getStorageKey() async {
    final user = await _authRepository?.getCurrentUser();
    if (user != null && user.id.isNotEmpty) {
      return 'aura_user_library_${user.id}';
    }
    return _keyLocalLibrary;
  }

  @override
  Future<List<LibraryItem>> getLibraryItems({LibraryCategory? category}) async {
    final key = await _getStorageKey();
    var rawList = _prefs.getStringList(key);

    // If switching to user account for the first time, fallback to guest local library
    if ((rawList == null || rawList.isEmpty) && key != _keyLocalLibrary) {
      rawList = _prefs.getStringList(_keyLocalLibrary) ?? [];
    }

    final items = (rawList ?? []).map((str) {
      return LibraryItem.fromJson(jsonDecode(str) as Map<String, dynamic>);
    }).toList();

    if (category != null) {
      return items.where((i) => i.category == category).toList();
    }
    return items;
  }

  @override
  Future<void> saveLibraryItem(LibraryItem item) async {
    final key = await _getStorageKey();
    final items = await getLibraryItems();
    final updated = List<LibraryItem>.from(items)
      ..removeWhere((i) => i.id == item.id && i.category == item.category)
      ..insert(0, item);

    final rawList = updated.map((i) => jsonEncode(i.toJson())).toList();
    await _prefs.setStringList(key, rawList);

    await syncWithCloud();
  }

  @override
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
  }) async {
    final progress = WatchProgress(
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      lastWatchedAt: DateTime.now(),
    );

    final category = progress.isFinished
        ? LibraryCategory.history
        : LibraryCategory.continueWatching;

    final item = LibraryItem(
      id: mediaId,
      title: title,
      posterPath: posterPath,
      backdropPath: backdropPath,
      type: type,
      category: category,
      progress: progress,
      updatedAt: DateTime.now(),
    );

    await saveLibraryItem(item);

    // Smart Delete Watched Episode: Trigger automatic background cleanup if progress >= 80%
    if (progress.percentage >= 0.80 &&
        seasonNumber != null &&
        episodeNumber != null) {
      try {
        final parsedId = int.tryParse(mediaId);
        if (parsedId != null) {
          final downloadRepo = DownloadRepositoryImpl();
          await downloadRepo.smartDeleteWatchedEpisode(
            parsedId,
            seasonNumber,
            episodeNumber,
          );
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> removeItem(String mediaId) async {
    final key = await _getStorageKey();
    final items = await getLibraryItems();
    final updated = items.where((i) => i.id != mediaId).toList();
    final rawList = updated.map((i) => jsonEncode(i.toJson())).toList();
    await _prefs.setStringList(key, rawList);

    await syncWithCloud();
  }

  @override
  Future<void> syncWithCloud() async {
    final user = await _authRepository?.getCurrentUser();
    if (user == null || !_cloudSync.isCloudAvailable) return;

    final localItems = await getLibraryItems();
    await _cloudSync.pushLibraryState(user.id, localItems);
  }
}
