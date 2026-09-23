import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/player/data/services/media_kit_player_service.dart';
import 'package:aura/features/player/domain/entities/player_state.dart';
import 'package:aura/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura/features/player/presentation/bloc/player_event.dart';

void main() {
  group('Player Stream Resilience & Multi-Source Fallback Tests', () {
    late MediaKitPlayerService playerService;
    late PlayerBloc bloc;

    setUp(() {
      playerService = MediaKitPlayerService.test();
      bloc = PlayerBloc(playerService: playerService);
    });

    tearDown(() {
      bloc.close();
    });

    test('PlayStreamEvent populates candidate streams and initializes active stream', () async {
      final candidates = [
        'https://cdn1.stream.test/master.m3u8',
        'https://cdn2.stream.test/backup.mp4',
      ];

      bloc.add(PlayStreamEvent(
        streamUrl: candidates[0],
        title: 'Test Movie',
        candidateStreams: candidates,
        candidateIndex: 0,
      ));

      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.candidateStreams, equals(candidates));
      expect(bloc.state.activeCandidateIndex, equals(0));
      expect(bloc.state.currentStreamUrl, equals(candidates[0]));
    });

    test('PlayerBloc automatically switches to second candidate on primary stream failure', () async {
      final candidates = [
        'https://cdn1.stream.test/broken.m3u8',
        'https://cdn2.stream.test/working.mp4',
      ];

      bloc.add(PlayStreamEvent(
        streamUrl: candidates[0],
        title: 'Test Movie',
        candidateStreams: candidates,
        candidateIndex: 0,
      ));

      await Future<void>.delayed(Duration.zero);

      // Simulate primary stream error event from player service
      bloc.add(const PlayerStateUpdatedEvent(AuraPlayerState(
        status: PlaybackStatus.error,
        errorMessage: 'HTTP 403 Forbidden',
        position: Duration(seconds: 42),
      )));

      await Future<void>.delayed(Duration.zero);

      // State should transition to retrying and select candidate[1]
      expect(bloc.state.status, equals(PlaybackStatus.retrying));
      expect(bloc.state.activeCandidateIndex, equals(1));
      expect(bloc.state.currentStreamUrl, equals(candidates[1]));
      expect(bloc.state.isRetrying, isTrue);
    });

    test('PlayerBloc terminates into clean error state when all stream candidates fail', () async {
      final candidates = [
        'https://cdn1.stream.test/broken1.m3u8',
        'https://cdn2.stream.test/broken2.mp4',
      ];

      bloc.add(PlayStreamEvent(
        streamUrl: candidates[1],
        title: 'Test Movie',
        candidateStreams: candidates,
        candidateIndex: 1, // On final candidate
      ));

      await Future<void>.delayed(Duration.zero);

      // Simulate failure on final candidate
      bloc.add(const PlayerStateUpdatedEvent(AuraPlayerState(
        status: PlaybackStatus.error,
        errorMessage: 'HTTP 404 Not Found',
      )));

      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, equals(PlaybackStatus.error));
      expect(bloc.state.errorMessage, contains('All available sources failed to load'));
    });
  });
}
