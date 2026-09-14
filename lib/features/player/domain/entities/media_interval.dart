// Represents a time interval within a video that can be skipped.

enum MediaIntervalType { intro, recap, credits }

/// Immutable value object describing a skip‑able interval.
class MediaInterval {
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
}
