import 'package:equatable/equatable.dart';

enum MediaIntervalType { intro, recap, credits }

/// Immutable value object describing a skip‑able interval.
class MediaInterval extends Equatable {
  final MediaIntervalType type;
  final Duration start;
  final Duration end;

  const MediaInterval({
    required this.type,
    required this.start,
    required this.end,
  });

  /// Returns `true` if [position] falls inside the interval.
  /// The comparison is inclusive of the start and exclusive of the end.
  bool contains(Duration position) => position >= start && position < end;

  /// Target position when skipping interval (`end + 0.5s`)
  Duration get skipTarget => end + const Duration(milliseconds: 500);

  @override
  List<Object?> get props => [type, start, end];
}

/// Helper container holding parsed interval timeline for media item
class MediaTimeline {
  final List<MediaInterval> intervals;

  const MediaTimeline({this.intervals = const []});

  MediaInterval? getIntervalAt(Duration position) {
    for (final interval in intervals) {
      if (interval.contains(position)) {
        return interval;
      }
    }
    return null;
  }

  MediaInterval? get intro => intervals.cast<MediaInterval?>().firstWhere(
      (i) => i?.type == MediaIntervalType.intro,
      orElse: () => null);

  MediaInterval? get recap => intervals.cast<MediaInterval?>().firstWhere(
      (i) => i?.type == MediaIntervalType.recap,
      orElse: () => null);

  MediaInterval? get credits => intervals.cast<MediaInterval?>().firstWhere(
      (i) => i?.type == MediaIntervalType.credits,
      orElse: () => null);
}
