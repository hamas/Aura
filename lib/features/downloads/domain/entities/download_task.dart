import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/media_item.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadTask extends Equatable {
  final String id;
  final int mediaId;
  final String title;
  final MediaType mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? episodeTitle;
  final String? posterPath;
  final String? backdropPath;
  final String downloadUrl;
  final String localFilePath;
  final DownloadStatus status;
  final int bytesDownloaded;
  final int totalBytes;
  final double downloadSpeed; // in bytes per second
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? error;

  final String qualityLabel;
  final String profileId;

  const DownloadTask({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
    this.posterPath,
    this.backdropPath,
    required this.downloadUrl,
    required this.localFilePath,
    this.qualityLabel = '1080p Web-DL',
    this.profileId = 'default',
    this.status = DownloadStatus.queued,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.downloadSpeed = 0.0,
    required this.createdAt,
    this.completedAt,
    this.error,
  });

  double get progressPercentage {
    if (totalBytes <= 0) return 0.0;
    final progress = bytesDownloaded / totalBytes;
    return progress.clamp(0.0, 1.0);
  }

  String get formattedProgressPercentage {
    return '${(progressPercentage * 100).toStringAsFixed(1)}%';
  }

  String get formattedSize {
    if (totalBytes <= 0) {
      return _formatBytes(bytesDownloaded);
    }
    return '${_formatBytes(bytesDownloaded)} / ${_formatBytes(totalBytes)}';
  }

  String get formattedTotalSize {
    return _formatBytes(totalBytes > 0 ? totalBytes : bytesDownloaded);
  }

  String get formattedSpeed {
    if (status != DownloadStatus.downloading || downloadSpeed <= 0) {
      return '';
    }
    return '${_formatBytes(downloadSpeed.toInt())}/s';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isQueued => status == DownloadStatus.queued;

  DownloadTask copyWith({
    String? id,
    int? mediaId,
    String? title,
    MediaType? mediaType,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
    String? posterPath,
    String? backdropPath,
    String? downloadUrl,
    String? localFilePath,
    String? qualityLabel,
    String? profileId,
    DownloadStatus? status,
    int? bytesDownloaded,
    int? totalBytes,
    double? downloadSpeed,
    DateTime? createdAt,
    DateTime? completedAt,
    String? error,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      qualityLabel: qualityLabel ?? this.qualityLabel,
      profileId: profileId ?? this.profileId,
      status: status ?? this.status,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        id,
        mediaId,
        title,
        mediaType,
        seasonNumber,
        episodeNumber,
        episodeTitle,
        posterPath,
        backdropPath,
        downloadUrl,
        localFilePath,
        qualityLabel,
        profileId,
        status,
        bytesDownloaded,
        totalBytes,
        downloadSpeed,
        createdAt,
        completedAt,
        error,
      ];
}
