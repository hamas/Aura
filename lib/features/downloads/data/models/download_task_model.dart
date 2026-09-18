import '../../../catalog/domain/entities/media_item.dart';
import '../../domain/entities/download_task.dart';

class DownloadTaskModel {
  final String id;
  final int mediaId;
  final String title;
  final String mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? episodeTitle;
  final String? posterPath;
  final String? backdropPath;
  final String downloadUrl;
  final String localFilePath;
  final String status;
  final int bytesDownloaded;
  final int totalBytes;
  final double downloadSpeed;
  final String qualityLabel;
  final String profileId;
  final Map<String, String>? httpHeaders;
  final String createdAt;
  final String? completedAt;
  final String? error;

  const DownloadTaskModel({
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
    this.httpHeaders,
    required this.status,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.downloadSpeed,
    required this.createdAt,
    this.completedAt,
    this.error,
  });

  factory DownloadTaskModel.fromJson(Map<String, dynamic> json) {
    return DownloadTaskModel(
      id: json['id'] as String,
      mediaId: json['mediaId'] as int,
      title: json['title'] as String,
      mediaType: json['mediaType'] as String? ?? 'movie',
      seasonNumber: json['seasonNumber'] as int?,
      episodeNumber: json['episodeNumber'] as int?,
      episodeTitle: json['episodeTitle'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      downloadUrl: json['downloadUrl'] as String,
      localFilePath: json['localFilePath'] as String,
      qualityLabel: json['qualityLabel'] as String? ?? '1080p Web-DL',
      profileId: json['profileId'] as String? ?? 'default',
      httpHeaders: (json['httpHeaders'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      status: json['status'] as String? ?? 'queued',
      bytesDownloaded: json['bytesDownloaded'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      downloadSpeed: (json['downloadSpeed'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] as String,
      completedAt: json['completedAt'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaId': mediaId,
      'title': title,
      'mediaType': mediaType,
      if (seasonNumber != null) 'seasonNumber': seasonNumber,
      if (episodeNumber != null) 'episodeNumber': episodeNumber,
      if (episodeTitle != null) 'episodeTitle': episodeTitle,
      if (posterPath != null) 'posterPath': posterPath,
      if (backdropPath != null) 'backdropPath': backdropPath,
      'downloadUrl': downloadUrl,
      'localFilePath': localFilePath,
      'qualityLabel': qualityLabel,
      'profileId': profileId,
      if (httpHeaders != null) 'httpHeaders': httpHeaders,
      'status': status,
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      'downloadSpeed': downloadSpeed,
      'createdAt': createdAt,
      if (completedAt != null) 'completedAt': completedAt,
      if (error != null) 'error': error,
    };
  }

  factory DownloadTaskModel.fromEntity(DownloadTask task) {
    return DownloadTaskModel(
      id: task.id,
      mediaId: task.mediaId,
      title: task.title,
      mediaType: task.mediaType.name,
      seasonNumber: task.seasonNumber,
      episodeNumber: task.episodeNumber,
      episodeTitle: task.episodeTitle,
      posterPath: task.posterPath,
      backdropPath: task.backdropPath,
      downloadUrl: task.downloadUrl,
      localFilePath: task.localFilePath,
      qualityLabel: task.qualityLabel,
      profileId: task.profileId,
      httpHeaders: task.httpHeaders,
      status: task.status.name,
      bytesDownloaded: task.bytesDownloaded,
      totalBytes: task.totalBytes,
      downloadSpeed: task.downloadSpeed,
      createdAt: task.createdAt.toIso8601String(),
      completedAt: task.completedAt?.toIso8601String(),
      error: task.error,
    );
  }

  DownloadTask toEntity() {
    DownloadStatus parsedStatus;
    try {
      parsedStatus = DownloadStatus.values.byName(status);
    } catch (_) {
      parsedStatus = DownloadStatus.queued;
    }

    final parsedMediaType =
        mediaType == 'series' ? MediaType.series : MediaType.movie;

    return DownloadTask(
      id: id,
      mediaId: mediaId,
      title: title,
      mediaType: parsedMediaType,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      posterPath: posterPath,
      backdropPath: backdropPath,
      downloadUrl: downloadUrl,
      localFilePath: localFilePath,
      qualityLabel: qualityLabel,
      profileId: profileId,
      httpHeaders: httpHeaders,
      status: parsedStatus,
      bytesDownloaded: bytesDownloaded,
      totalBytes: totalBytes,
      downloadSpeed: downloadSpeed,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      completedAt: completedAt != null ? DateTime.tryParse(completedAt!) : null,
      error: error,
    );
  }
}
