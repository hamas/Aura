import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/player/domain/entities/stream_track.dart';
import 'package:aura/features/player/domain/entities/player_state.dart';

void main() {
  group('Audio Track Extraction & Buffer Telemetry Tests', () {
    test('AudioTrackInfo properties and language formatting', () {
      const track1 = AudioTrackInfo(id: '1', title: 'English [Original]', language: 'eng');
      const track2 = AudioTrackInfo(id: '2', title: 'Spanish 5.1', language: 'spa');

      expect(track1.id, equals('1'));
      expect(track1.language, equals('eng'));
      expect(track2.title, equals('Spanish 5.1'));
    });

    test('AuraPlayerState calculates bufferCushion correctly', () {
      const state1 = AuraPlayerState(
        position: Duration(seconds: 10),
        buffer: Duration(seconds: 35),
      );
      expect(state1.bufferCushion, equals(const Duration(seconds: 25)));

      const state2 = AuraPlayerState(
        position: Duration(seconds: 40),
        buffer: Duration(seconds: 30),
      );
      expect(state2.bufferCushion, equals(Duration.zero));
    });
  });
}
