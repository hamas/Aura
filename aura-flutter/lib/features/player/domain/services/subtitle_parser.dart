import 'dart:convert';
import 'dart:typed_data';
import '../entities/subtitle_cue.dart';

class SubtitleParser {
  /// Decode raw bytes using encoding fallback (UTF-8 -> Windows-1252 -> ISO-8859-1)
  static String decodeText(Uint8List bytes) {
    try {
      return const Utf8Decoder(allowMalformed: false).convert(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }

  /// Parse SRT or VTT string content into SubtitleCues
  static List<SubtitleCue> parse(String content) {
    final cues = <SubtitleCue>[];
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isEmpty) continue;

      int timeLineIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timeLineIndex = i;
          break;
        }
      }

      if (timeLineIndex == -1) continue;

      final timeLine = lines[timeLineIndex];
      final timeParts = timeLine.split('-->');
      if (timeParts.length < 2) continue;

      final start = parseTimestamp(timeParts[0].trim());
      final end = parseTimestamp(timeParts[1].trim().split(' ').first);

      if (start == null || end == null) continue;

      final textLines = lines.sublist(timeLineIndex + 1);
      final text = textLines.join('\n').trim();

      if (text.isNotEmpty) {
        cues.add(SubtitleCue(start: start, end: end, text: text));
      }
    }

    return cues;
  }

  /// Parse SRT/VTT timestamp: 00:01:20,000 or 00:01:20.000 or 01:20.000
  static Duration? parseTimestamp(String timestamp) {
    try {
      final clean = timestamp.replaceAll(',', '.');
      final parts = clean.split(':');
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secParts = parts[2].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1
            ? int.parse(secParts[1].padRight(3, '0').substring(0, 3))
            : 0;
        return Duration(
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            milliseconds: millis);
      } else if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final secParts = parts[1].split('.');
        final seconds = int.parse(secParts[0]);
        final millis = secParts.length > 1
            ? int.parse(secParts[1].padRight(3, '0').substring(0, 3))
            : 0;
        return Duration(
            minutes: minutes, seconds: seconds, milliseconds: millis);
      }
    } catch (_) {}
    return null;
  }
}
