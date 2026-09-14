import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/media_item.dart';
import '../../domain/entities/download_task.dart';

enum DownloadsStatus {
  initial,
  loading,
  ready,
  error,
}

class DownloadsState extends Equatable {
  final DownloadsStatus status;
  final List<DownloadTask> tasks;
  final int totalStorageBytes;
  final String? errorMessage;

  const DownloadsState({
    this.status = DownloadsStatus.initial,
    this.tasks = const [],
    this.totalStorageBytes = 0,
    this.errorMessage,
  });

  /// Formatted storage string (e.g. 1.2 GB used).
  String get formattedTotalStorage {
    if (totalStorageBytes <= 0) return '0 B used';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = totalStorageBytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]} used';
  }

  /// Finds task by ID.
  DownloadTask? getTask(String taskId) {
    try {
      return tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  /// Finds task by media metadata (useful for movie detail or episode check).
  DownloadTask? getMediaTask({
    required int mediaId,
    required MediaType mediaType,
    int? seasonNumber,
    int? episodeNumber,
  }) {
    try {
      return tasks.firstWhere(
        (t) =>
            t.mediaId == mediaId &&
            t.mediaType == mediaType &&
            t.seasonNumber == seasonNumber &&
            t.episodeNumber == episodeNumber,
      );
    } catch (_) {
      return null;
    }
  }

  /// List of completed downloads.
  List<DownloadTask> get completedTasks =>
      tasks.where((t) => t.isCompleted).toList();

  /// List of active/in-progress/queued downloads.
  List<DownloadTask> get activeTasks =>
      tasks.where((t) => !t.isCompleted).toList();

  /// Grouped completed movies.
  List<DownloadTask> get completedMovies => tasks
      .where((t) => t.isCompleted && t.mediaType == MediaType.movie)
      .toList();

  /// Grouped completed series episodes.
  List<DownloadTask> get completedSeriesEpisodes => tasks
      .where((t) => t.isCompleted && t.mediaType == MediaType.series)
      .toList();

  DownloadsState copyWith({
    DownloadsStatus? status,
    List<DownloadTask>? tasks,
    int? totalStorageBytes,
    String? errorMessage,
  }) {
    return DownloadsState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      totalStorageBytes: totalStorageBytes ?? this.totalStorageBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        totalStorageBytes,
        errorMessage,
      ];
}
