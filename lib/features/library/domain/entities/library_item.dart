import 'package:equatable/equatable.dart';

enum LibraryCategory { watchlist, history, continueWatching }

class WatchProgress extends Equatable {
  final int positionSeconds;
  final int durationSeconds;
  final int? seasonNumber;
  final int? episodeNumber;
  final DateTime lastWatchedAt;

  const WatchProgress({
    required this.positionSeconds,
    required this.durationSeconds,
    this.seasonNumber,
    this.episodeNumber,
    required this.lastWatchedAt,
  });

  double get percentage => durationSeconds > 0
      ? (positionSeconds / durationSeconds).clamp(0.0, 1.0)
      : 0.0;

  bool get isFinished => percentage >= 0.90;

  factory WatchProgress.fromJson(Map<String, dynamic> json) {
    return WatchProgress(
      positionSeconds: json['position_seconds'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      seasonNumber: json['season_number'] as int?,
      episodeNumber: json['episode_number'] as int?,
      lastWatchedAt: json['last_watched_at'] != null
          ? DateTime.parse(json['last_watched_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'position_seconds': positionSeconds,
        'duration_seconds': durationSeconds,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'last_watched_at': lastWatchedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        positionSeconds,
        durationSeconds,
        seasonNumber,
        episodeNumber,
        lastWatchedAt,
      ];
}

class LibraryItem extends Equatable {
  final String id; // TMDB or IMDb ID
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String type; // 'movie' or 'series'
  final LibraryCategory category;
  final WatchProgress? progress;
  final DateTime updatedAt;

  const LibraryItem({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.type,
    required this.category,
    this.progress,
    required this.updatedAt,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      type: json['type'] as String? ?? 'movie',
      category: LibraryCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => LibraryCategory.watchlist,
      ),
      progress: json['progress'] != null
          ? WatchProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'type': type,
        'category': category.name,
        'progress': progress?.toJson(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [id, title, posterPath, type, category, progress, updatedAt];
}
