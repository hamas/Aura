import 'package:equatable/equatable.dart';

/// Fired by the Smart Download manager when a tracked episode crosses the
/// 90 % playback threshold. The manager reacts by deleting the episode file
/// and queueing the next buffer of episodes.
class PlaybackCompletionEvent extends Equatable {
  /// The [DownloadTask.id] of the episode that was watched.
  final String completedTaskId;

  /// The series media ID, used to look up subsequent episodes.
  final int seriesMediaId;

  /// The season number of the completed episode.
  final int seasonNumber;

  /// The episode number of the completed episode.
  final int episodeNumber;

  const PlaybackCompletionEvent({
    required this.completedTaskId,
    required this.seriesMediaId,
    required this.seasonNumber,
    required this.episodeNumber,
  });

  @override
  List<Object?> get props => [
        completedTaskId,
        seriesMediaId,
        seasonNumber,
        episodeNumber,
      ];
}
