import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/player/data/services/media_kit_player_service.dart';
import 'package:aura/features/player/domain/entities/player_state.dart';
import 'package:aura/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura/features/player/presentation/bloc/player_event.dart';

void main() {
  group('TV Series Binge Navigation & Auto-Play Countdown Tests', () {
    late MediaKitPlayerService playerService;
    late PlayerBloc bloc;

    setUp(() {
      playerService = MediaKitPlayerService.test();
      bloc = PlayerBloc(playerService: playerService);
    });

    tearDown(() {
      bloc.close();
    });

    test('PlayerBloc triggers showNextEpisodeCountdown when remaining duration <= 20 seconds', () async {
      bloc.add(const PlayerStateUpdatedEvent(AuraPlayerState(
        position: Duration(seconds: 110),
        duration: Duration(seconds: 125), // 15 seconds remaining
        status: PlaybackStatus.playing,
      )));

      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.showNextEpisodeCountdown, isTrue);
      expect(bloc.state.remainingCountdownSeconds, equals(15));
    });

    test('PlayerBloc hides countdown when remaining duration > 20 seconds', () async {
      bloc.add(const PlayerStateUpdatedEvent(AuraPlayerState(
        position: Duration(seconds: 30),
        duration: Duration(seconds: 120), // 90 seconds remaining
        status: PlaybackStatus.playing,
      )));

      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.showNextEpisodeCountdown, isFalse);
    });
  });
}
