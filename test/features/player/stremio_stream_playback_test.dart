import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/addons/domain/entities/addon_stream.dart';
import 'package:aura/features/player/domain/entities/player_state.dart';
import 'package:aura/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura/features/player/presentation/bloc/player_event.dart';
import 'package:aura/features/player/data/services/media_kit_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stremio Stream Playback & Proxy Headers Tests', () {
    test('AddonStream correctly parses proxyHeaders from behaviorHints', () {
      final json = {
        'name': '1080p Stream',
        'title': 'Test Movie 1080p',
        'url': 'https://stream.example.com/video.mp4',
        'behaviorHints': {
          'proxyHeaders': {
            'request': {
              'Referer': 'https://provider.example.com/',
              'User-Agent': 'CustomClient/1.0',
            }
          }
        }
      };

      final stream = AddonStream.fromJson(json, addonName: 'Test Addon');
      expect(stream.isDirectHttp, isTrue);
      expect(stream.isTorrent, isFalse);
      expect(stream.headers, isNotNull);
      expect(stream.headers?['Referer'], equals('https://provider.example.com/'));
      expect(stream.headers?['User-Agent'], equals('CustomClient/1.0'));
    });

    test('AddonStream identifies infoHash torrent-only streams', () {
      final json = {
        'name': '4K Torrent',
        'title': 'Movie 4K',
        'infoHash': 'abc123def4567890123456789012345678901234',
        'fileIdx': 1,
      };

      final stream = AddonStream.fromJson(json, addonName: 'Torrentio');
      expect(stream.isTorrent, isTrue);
      expect(stream.isDirectHttp, isFalse);
      expect(stream.url, isNull);
    });

    test('PlayerBloc dispatches PlayStreamEvent with headers to player service', () async {
      final mockService = MediaKitPlayerService.test(
        initialState: const AuraPlayerState(status: PlaybackStatus.paused),
      );
      final bloc = PlayerBloc(playerService: mockService);

      const streamUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      const customHeaders = {
        'Referer': 'https://custom-referer.com',
        'User-Agent': 'AuraTestAgent/1.0',
      };

      bloc.add(const PlayStreamEvent(
        streamUrl: streamUrl,
        title: 'Big Buck Bunny',
        subtitle: 'Animation',
        httpHeaders: customHeaders,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.status, equals(PlaybackStatus.buffering));
      expect(bloc.state.currentStreamUrl, equals(streamUrl));
      await bloc.close();
    });
  });
}
