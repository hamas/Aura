import 'package:equatable/equatable.dart';

class SubtitleCue extends Equatable {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  SubtitleCue shift(double offsetSeconds) {
    final offsetMs = (offsetSeconds * 1000).round();
    final newStart = start.inMilliseconds + offsetMs;
    final newEnd = end.inMilliseconds + offsetMs;

    return SubtitleCue(
      start: Duration(milliseconds: newStart < 0 ? 0 : newStart),
      end: Duration(milliseconds: newEnd < 0 ? 0 : newEnd),
      text: text,
    );
  }

  @override
  List<Object?> get props => [start, end, text];
}
