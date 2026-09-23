import 'dart:typed_data';
import 'package:aura/features/player/domain/entities/player_state.dart';
import 'package:aura/features/player/domain/entities/subtitle_cue.dart';
import 'package:aura/features/player/domain/entities/stream_track.dart';
import 'package:aura/features/player/domain/services/subtitle_parser.dart';
import 'package:aura/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura/features/player/presentation/bloc/player_event.dart';
import 'package:aura/features/player/presentation/subtitles/widgets/dual_subtitle_overlay.dart';
import 'package:aura/features/player/presentation/subtitles/widgets/subtitle_sync_hud.dart';
import 'package:aura/features/player/data/services/media_kit_player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subtitle Engine & Auto-Sync Offset HUD Tests', () {
    test('SubtitleParser correctly parses SRT content and handles timestamps',
        () {
      const srtContent = '''
1
00:00:01,000 --> 00:00:04,500
Hello, welcome to Aura!

2
00:00:05,000 --> 00:00:08,200
Enjoy dual-language subtitles.
''';

      final cues = SubtitleParser.parse(srtContent);
      expect(cues.length, equals(2));
      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(
          cues[0].end, equals(const Duration(seconds: 4, milliseconds: 500)));
      expect(cues[0].text, equals('Hello, welcome to Aura!'));

      expect(cues[1].start, equals(const Duration(seconds: 5)));
      expect(
          cues[1].end, equals(const Duration(seconds: 8, milliseconds: 200)));
      expect(cues[1].text, equals('Enjoy dual-language subtitles.'));
    });

    test('SubtitleParser correctly parses VTT content', () {
      const vttContent = '''
WEBVTT

00:01.000 --> 00:03.500
WebVTT subtitle cue text
''';

      final cues = SubtitleParser.parse(vttContent);
      expect(cues.length, equals(1));
      expect(cues[0].start, equals(const Duration(seconds: 1)));
      expect(
          cues[0].end, equals(const Duration(seconds: 3, milliseconds: 500)));
      expect(cues[0].text, equals('WebVTT subtitle cue text'));
    });

    test('SubtitleParser decodes multi-encoding bytes correctly', () {
      final utf8Bytes = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"
      expect(SubtitleParser.decodeText(utf8Bytes), equals('Hello'));

      final latin1Bytes = Uint8List.fromList(
          [0xE9, 108, 201, 118, 224, 116, 101]); // Latin1 characters
      expect(SubtitleParser.decodeText(latin1Bytes), isNotEmpty);
    });

    test('SubtitleCue shift adjusts timestamp offset accurately', () {
      const cue = SubtitleCue(
        start: Duration(seconds: 2),
        end: Duration(seconds: 5),
        text: 'Sync test',
      );

      final shiftedPlus = cue.shift(1.5);
      expect(shiftedPlus.start, equals(const Duration(milliseconds: 3500)));
      expect(shiftedPlus.end, equals(const Duration(milliseconds: 6500)));

      final shiftedMinus = cue.shift(-3.0);
      expect(shiftedMinus.start, equals(Duration.zero));
    });

    test('PlayerBloc handles Subtitle Offset and Dual Subtitle Track Events',
        () async {
      final playerService = MediaKitPlayerService.test();
      final bloc = PlayerBloc(playerService: playerService);

      expect(bloc.state.subtitleOffset, equals(0.0));
      expect(bloc.state.selectedSecondarySubtitleTrack, isNull);

      bloc.add(const SetSubtitleOffsetEvent(2.5));
      await expectLater(
        bloc.stream,
        emits(predicate<AuraPlayerState>((s) => s.subtitleOffset == 2.5)),
      );

      bloc.add(const NudgeSubtitleOffsetEvent(-0.5));
      await expectLater(
        bloc.stream,
        emits(predicate<AuraPlayerState>((s) => s.subtitleOffset == 2.0)),
      );

      const track =
          SubtitleTrackInfo(id: 'es', title: 'Spanish', language: 'es');
      bloc.add(const SelectSecondarySubtitleTrackEvent(track));
      await expectLater(
        bloc.stream,
        emits(predicate<AuraPlayerState>(
            (s) => s.selectedSecondarySubtitleTrack?.id == 'es')),
      );

      await bloc.close();
    });

    testWidgets('SubtitleSyncHud renders quick nudge buttons and slider',
        (tester) async {
      double currentOffset = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtitleSyncHud(
              currentOffset: currentOffset,
              onOffsetChanged: (val) => currentOffset = val,
              onNudgeOffset: (delta) => currentOffset += delta,
              onReset: () => currentOffset = 0.0,
            ),
          ),
        ),
      );

      expect(find.text('Subtitle Sync Offset'), findsOneWidget);
      expect(find.text('+0.0s'), findsOneWidget);
      expect(find.text('-0.5s'), findsOneWidget);
      expect(find.text('+0.5s'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.text('+0.5s'));
      expect(currentOffset, equals(0.5));
    });

    testWidgets(
        'DualSubtitleOverlay displays primary and secondary subtitle tracks simultaneously',
        (tester) async {
      const primaryCue = SubtitleCue(
        start: Duration(seconds: 1),
        end: Duration(seconds: 5),
        text: 'Primary English Subtitle',
      );
      const secondaryCue = SubtitleCue(
        start: Duration(seconds: 1),
        end: Duration(seconds: 5),
        text: 'Secondary Spanish Subtitle',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualSubtitleOverlay(
              primaryCues: [primaryCue],
              secondaryCues: [secondaryCue],
              currentPosition: Duration(seconds: 2),
            ),
          ),
        ),
      );

      expect(find.text('Primary English Subtitle'), findsOneWidget);
      expect(find.text('Secondary Spanish Subtitle'), findsOneWidget);
    });
  });
}
