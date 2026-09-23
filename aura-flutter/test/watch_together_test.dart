import 'package:aura/features/watch_together/data/services/watch_together_service.dart';
import 'package:aura/features/watch_together/domain/entities/watch_room_session.dart';
import 'package:aura/features/watch_together/presentation/widgets/watch_together_overlay_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Watch Together Multi-User Synchronized Watch Rooms Tests', () {
    test('WatchRoomSession generates valid AURA-XXXX room codes', () {
      final code1 = WatchRoomSession.generateRoomCode();
      final code2 = WatchRoomSession.generateRoomCode();

      expect(code1, startsWith('AURA-'));
      expect(code1.length, equals(9)); // AURA- + 4 alphanumeric chars
      expect(code2, startsWith('AURA-'));
      expect(code1, isNot(equals(code2)));
    });

    test('WatchTogetherService creates room and broadcasts sync events',
        () async {
      final service = WatchTogetherService();
      final session = await service.createRoom(
        mediaId: 'movie_123',
        streamUrl: 'https://cdn.example.com/movie_123.mp4',
        hostDisplayName: 'Alice',
      );

      expect(session.roomCode, startsWith('AURA-'));
      expect(session.participants.length, equals(1));
      expect(session.participants.first.role, equals(WatchRoomRole.host));

      final events = <WatchSyncEvent>[];
      service.eventStream.listen(events.add);

      final event = WatchSyncEvent(
        type: WatchSyncEventType.play,
        senderId: 'alice_id',
        position: const Duration(seconds: 10),
        timestamp: DateTime.now(),
      );

      service.broadcastEvent(event);
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(1));
      expect(events.first.type, equals(WatchSyncEventType.play));
      expect(service.currentSession?.isPlaying, isTrue);

      await service.dispose();
    });

    test('Drift correction identifies when client drifts > 1.5s from host', () {
      const hostPos = Duration(seconds: 100);

      // Minor drift (0.8s) -> No correction
      final minorCorrection = WatchTogetherService.calculateDriftCorrection(
        clientPos: const Duration(milliseconds: 99200),
        hostPos: hostPos,
      );
      expect(minorCorrection, isNull);

      // Major drift (2.5s) -> Correction returned
      final majorCorrection = WatchTogetherService.calculateDriftCorrection(
        clientPos: const Duration(milliseconds: 97500),
        hostPos: hostPos,
      );
      expect(majorCorrection, equals(hostPos));
    });

    testWidgets(
        'WatchTogetherOverlayHUD renders room code and participant badge',
        (tester) async {
      const session = WatchRoomSession(
        roomCode: 'AURA-9999',
        mediaId: 'm1',
        streamUrl: 'http://stream.mp4',
        hostId: 'h1',
        participants: [
          WatchRoomParticipant(
            id: 'h1',
            displayName: 'Host User',
            role: WatchRoomRole.host,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WatchTogetherOverlayHUD(
              session: session,
              onSendReaction: (_) {},
              onToggleHostControl: (_) {},
              onLeaveRoom: () {},
            ),
          ),
        ),
      );

      expect(find.text('AURA-9999'), findsOneWidget);
      expect(find.text('1 LIVE'), findsOneWidget);
    });
  });
}
