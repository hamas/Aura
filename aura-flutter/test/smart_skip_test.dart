import 'package:aura/features/player/data/services/media_kit_player_service.dart';
import 'package:aura/features/player/domain/entities/media_interval.dart';
import 'package:aura/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura/features/player/presentation/bloc/player_event.dart';
import 'package:aura/features/player/presentation/widgets/skip_interval_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Smart Skip Engine Unit & Widget Tests', () {
    test(
        'MediaInterval correctly identifies timestamp boundaries and skip target',
        () {
      const interval = MediaInterval(
        type: MediaIntervalType.intro,
        start: Duration(seconds: 90),
        end: Duration(seconds: 180),
      );

      expect(interval.contains(const Duration(seconds: 89)), isFalse);
      expect(interval.contains(const Duration(seconds: 90)), isTrue);
      expect(interval.contains(const Duration(seconds: 150)), isTrue);
      expect(interval.contains(const Duration(seconds: 180)), isFalse);

      // Verify seek target calculation (end + 0.5s)
      expect(interval.skipTarget, equals(const Duration(milliseconds: 180500)));
    });

    test('PlayerBloc detects active interval and executes manual interval skip',
        () async {
      final playerService = MediaKitPlayerService.test();
      final bloc = PlayerBloc(playerService: playerService);

      const intro = MediaInterval(
        type: MediaIntervalType.intro,
        start: Duration(seconds: 60),
        end: Duration(seconds: 120),
      );

      bloc.add(const SetMediaIntervalsEvent([intro]));
      await Future<void>.delayed(Duration.zero);

      // Simulate playback entering intro boundary
      bloc.add(PlayerStateUpdatedEvent(
        bloc.state.copyWith(position: const Duration(seconds: 75)),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.activeInterval, equals(intro));

      // Trigger manual skip
      bloc.add(const SkipCurrentIntervalEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.position, equals(const Duration(milliseconds: 120500)));
      expect(bloc.state.activeInterval, isNull);

      await bloc.close();
    });

    test('PlayerBloc executes auto-skip when autoSkipIntros setting is enabled',
        () async {
      final playerService = MediaKitPlayerService.test();
      final bloc = PlayerBloc(playerService: playerService);

      const recap = MediaInterval(
        type: MediaIntervalType.recap,
        start: Duration(seconds: 10),
        end: Duration(seconds: 40),
      );

      bloc.add(const SetAutoSkipIntrosEvent(true));
      bloc.add(const SetMediaIntervalsEvent([recap]));
      await Future<void>.delayed(Duration.zero);

      // Simulate entering recap interval
      bloc.add(PlayerStateUpdatedEvent(
        bloc.state.copyWith(position: const Duration(seconds: 15)),
      ));
      await Future<void>.delayed(Duration.zero);

      // Should automatically seek to target position (40.5s)
      expect(bloc.state.position, equals(const Duration(milliseconds: 40500)));

      await bloc.close();
    });

    testWidgets('SkipIntervalPill renders intro label and handles skip tap',
        (tester) async {
      var skipped = false;
      const interval = MediaInterval(
        type: MediaIntervalType.intro,
        start: Duration(seconds: 90),
        end: Duration(seconds: 180),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkipIntervalPill(
              interval: interval,
              onSkip: () => skipped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SKIP INTRO'), findsOneWidget);

      await tester.tap(find.text('SKIP INTRO'));
      await tester.pump();

      expect(skipped, isTrue);
    });

    testWidgets(
        'NextEpisodeCountdownCard renders countdown and triggers play next',
        (tester) async {
      var nextTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextEpisodeCountdownCard(
              onPlayNext: () => nextTriggered = true,
              onDismiss: () {},
              countdownSeconds: 1,
            ),
          ),
        ),
      );

      expect(find.text('Next Episode'), findsOneWidget);
      expect(find.text('Play Now'), findsOneWidget);

      await tester.tap(find.text('Play Now'));
      await tester.pump();

      expect(nextTriggered, isTrue);
    });
  });
}
