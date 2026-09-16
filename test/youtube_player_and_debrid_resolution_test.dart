import 'package:aura/core/errors/exceptions.dart';
import 'package:aura/features/debrid/data/datasources/real_debrid_api_client.dart';
import 'package:aura/features/debrid/data/repositories/debrid_repository_impl.dart';
import 'package:aura/features/debrid/domain/entities/debrid_account.dart';
import 'package:aura/features/debrid/domain/repositories/debrid_repository.dart';
import 'package:aura/features/engine/common/stream_engine.dart';
import 'package:aura/features/engine/http_debrid_engine.dart';
import 'package:aura/features/player/domain/entities/player_state.dart';
import 'package:aura/features/player/presentation/widgets/components/player_bottom_control_bar.dart';
import 'package:aura/features/player/presentation/widgets/components/player_gesture_feedback_overlay.dart';
import 'package:aura/features/player/presentation/widgets/components/player_top_control_bar.dart';
import 'package:aura/core/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock RealDebridApiClient
class MockRealDebridApiClient extends RealDebridApiClient {
  String? lastUnrestrictedLink;
  String? lastAddedMagnet;
  String? lastSelectedFiles;

  @override
  Future<String> unrestrictLink(String token, String link) async {
    lastUnrestrictedLink = link;
    return 'https://s12.download.real-debrid.com/d/XYZ123/video.mp4';
  }

  @override
  Future<String> addMagnet(String token, String magnet) async {
    lastAddedMagnet = magnet;
    return 'TORRENT_ID_123';
  }

  @override
  Future<void> selectFiles(String token, String torrentId,
      {String fileIds = 'all'}) async {
    lastSelectedFiles = fileIds;
  }

  @override
  Future<Map<String, dynamic>> getTorrentInfo(
      String token, String torrentId) async {
    return {
      'id': torrentId,
      'status': 'downloaded',
      'links': [
        'https://real-debrid.com/d/FILE_1',
        'https://real-debrid.com/d/FILE_2',
        'https://real-debrid.com/d/FILE_3',
      ],
    };
  }
}

// Mock Uncached RealDebridApiClient (status: downloading)
class MockUncachedRealDebridApiClient extends RealDebridApiClient {
  @override
  Future<String> addMagnet(String token, String magnet) async => 'UNCACHED_ID';

  @override
  Future<void> selectFiles(String token, String torrentId,
      {String fileIds = 'all'}) async {}

  @override
  Future<Map<String, dynamic>> getTorrentInfo(
      String token, String torrentId) async {
    return {
      'id': torrentId,
      'status': 'downloading',
      'progress': 12,
      'links': <dynamic>[],
    };
  }
}

// Mock SecureStorageService
class MockSecureStorageService extends SecureStorageService {
  String? _apiKey = 'VALID_TEST_API_KEY';

  @override
  Future<String?> getRealDebridApiKey() async => _apiKey;

  @override
  Future<void> saveRealDebridApiKey(String key) async => _apiKey = key;

  @override
  Future<void> deleteRealDebridApiKey() async => _apiKey = null;
}

// Mock DebridRepository
class MockDebridRepository implements DebridRepository {
  bool hasToken = true;
  String? lastUnrestrictedLink;
  String? lastUnrestrictedMagnet;
  int? lastFileIndex;

  @override
  Future<bool> hasValidToken() async => hasToken;

  @override
  Future<String> unrestrictLink(String link) async {
    lastUnrestrictedLink = link;
    return 'https://s12.download.real-debrid.com/d/FINAL_DIRECT_CDN/movie.mp4';
  }

  @override
  Future<String> unrestrictMagnetOrHash(String magnetOrInfoHash,
      {int? fileIndex}) async {
    lastUnrestrictedMagnet = magnetOrInfoHash;
    lastFileIndex = fileIndex;
    return 'https://s12.download.real-debrid.com/d/MAGNET_RESOLVED/movie.mp4';
  }

  @override
  Future<DebridAccount> getAccountDetails() async => throw UnimplementedError();

  @override
  Future<void> removeToken() async {
    hasToken = false;
  }

  @override
  Future<void> saveApiToken(String token) async {
    hasToken = true;
  }
}

void main() {
  group('Part 1: Stream Resolution & Infinite Buffering Fixes', () {
    test('DebridRepositoryImpl branches immediately on HTTP(S) input in unrestrictMagnetOrHash',
        () async {
      final mockClient = MockRealDebridApiClient();
      final mockStorage = MockSecureStorageService();
      final repo = DebridRepositoryImpl(
        apiClient: mockClient,
        secureStorage: mockStorage,
      );

      const debridLanding = 'https://real-debrid.com/d/TEST_LANDING';
      final result = await repo.unrestrictMagnetOrHash(debridLanding);

      expect(mockClient.lastUnrestrictedLink, equals(debridLanding));
      expect(result, equals('https://s12.download.real-debrid.com/d/XYZ123/video.mp4'));
    });

    test('DebridRepositoryImpl selects fileIndex correctly for multi-file torrent packs',
        () async {
      final mockClient = MockRealDebridApiClient();
      final mockStorage = MockSecureStorageService();
      final repo = DebridRepositoryImpl(
        apiClient: mockClient,
        secureStorage: mockStorage,
      );

      const magnet = 'magnet:?xt=urn:btih:ABCDEF123456';
      final result = await repo.unrestrictMagnetOrHash(magnet, fileIndex: 2);

      expect(mockClient.lastAddedMagnet, equals(magnet));
      expect(mockClient.lastSelectedFiles, equals('2'));
      expect(mockClient.lastUnrestrictedLink, equals('https://real-debrid.com/d/FILE_2'));
      expect(result, equals('https://s12.download.real-debrid.com/d/XYZ123/video.mp4'));
    });

    test('DebridRepositoryImpl fails fast when torrent status is downloading (uncached)',
        () async {
      final mockClient = MockUncachedRealDebridApiClient();
      final mockStorage = MockSecureStorageService();
      final repo = DebridRepositoryImpl(
        apiClient: mockClient,
        secureStorage: mockStorage,
      );

      const magnet = 'magnet:?xt=urn:btih:UNCACHED123';
      expect(
        () => repo.unrestrictMagnetOrHash(magnet),
        throwsA(isA<DebridException>().having(
          (e) => e.message,
          'message',
          contains('not cached on Real-Debrid yet'),
        )),
      );
    });

    test('HttpDebridEngine unrestricts Debrid landing URLs to direct CDN links',
        () async {
      final mockRepo = MockDebridRepository();
      final engine = HttpDebridEngine(debridRepository: mockRepo);

      const landingUrl = 'https://real-debrid.com/d/XYZ789';
      final resolved = await engine.resolveStream(
        rawUrlOrInfoHash: landingUrl,
        extraParams: {
          'title': 'Test Movie',
          'quality': '4K UHD',
        },
      );

      expect(mockRepo.lastUnrestrictedLink, equals(landingUrl));
      expect(resolved.streamUrl,
          equals('https://s12.download.real-debrid.com/d/FINAL_DIRECT_CDN/movie.mp4'));
      expect(resolved.sourceType, equals(StreamSourceType.debrid));
      expect(resolved.httpHeaders?['User-Agent'], contains('Mozilla/5.0'));
      expect(resolved.title, equals('Test Movie'));
    });

    test('HttpDebridEngine unrestricts supported hoster links (1Fichier, Rapidgator, Mega)',
        () async {
      final mockRepo = MockDebridRepository();
      final engine = HttpDebridEngine(debridRepository: mockRepo);

      const hosterUrl = 'https://rapidgator.net/file/12345/movie.mkv';
      final resolved = await engine.resolveStream(
        rawUrlOrInfoHash: hosterUrl,
      );

      expect(mockRepo.lastUnrestrictedLink, equals(hosterUrl));
      expect(resolved.streamUrl, contains('download.real-debrid.com'));
    });

    test('HttpDebridEngine forwards fileIdx to unrestrictMagnetOrHash',
        () async {
      final mockRepo = MockDebridRepository();
      final engine = HttpDebridEngine(debridRepository: mockRepo);

      const infoHash = '4e868f7b7f14187027582b6b23fb271e8bf0d843';
      final resolved = await engine.resolveStream(
        rawUrlOrInfoHash: infoHash,
        extraParams: {'fileIdx': 3},
      );

      expect(mockRepo.lastUnrestrictedMagnet, equals(infoHash));
      expect(mockRepo.lastFileIndex, equals(3));
      expect(resolved.streamUrl, contains('download.real-debrid.com'));
    });
  });

  group('Part 2: Modern YouTube-Style Player UI & Gestures Tests', () {
    testWidgets('PlayerGestureFeedbackOverlay renders -10s and +10s seek badges with ripples',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerGestureFeedbackOverlay(
              showLeftSeekRipple: true,
              showRightSeekRipple: false,
              leftSeekSeconds: 10,
              showBrightnessHud: false,
              currentBrightness: 0.5,
              showVolumeHud: false,
              currentVolume: 80,
              isScrubbing: false,
              scrubOffset: Duration.zero,
              scrubTarget: Duration.zero,
              size: const Size(800, 450),
              formatDuration: (d) => '00:10',
            ),
          ),
        ),
      );

      expect(find.text('-10s'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerGestureFeedbackOverlay(
              showLeftSeekRipple: false,
              showRightSeekRipple: true,
              rightSeekSeconds: 20,
              showBrightnessHud: false,
              currentBrightness: 0.5,
              showVolumeHud: false,
              currentVolume: 80,
              isScrubbing: false,
              scrubOffset: Duration.zero,
              scrubTarget: Duration.zero,
              size: const Size(800, 450),
              formatDuration: (d) => '00:20',
            ),
          ),
        ),
      );

      expect(find.text('+20s'), findsOneWidget);
    });

    testWidgets('PlayerTopControlBar renders title, subtitle, and action buttons',
        (tester) async {
      bool backPressed = false;
      BoxFit? newFit;

      const testState = AuraPlayerState(
        title: 'Interstellar',
        subtitle: '4K Remux HDR',
        fit: BoxFit.contain,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerTopControlBar(
              state: testState,
              onBack: () => backPressed = true,
              onAspectRatioChange: (fit) => newFit = fit,
              onSpeedChange: (_) {},
              onShowSubtitlePicker: () {},
              onShowAudioPicker: () {},
            ),
          ),
        ),
      );

      expect(find.text('Interstellar'), findsOneWidget);
      expect(find.text('4K Remux HDR'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(IconButton).first);
      expect(backPressed, isTrue);

      // Tap aspect ratio button
      await tester.tap(find.byTooltip('Original aspect ratio'));
      expect(newFit, equals(BoxFit.cover));
    });

    testWidgets('PlayerBottomControlBar renders YouTube-style timecode and scrubber',
        (tester) async {
      Duration? seekTarget;

      const testState = AuraPlayerState(
        position: Duration(minutes: 4, seconds: 12),
        duration: Duration(hours: 1, minutes: 48, seconds: 30),
        buffer: Duration(minutes: 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerBottomControlBar(
              state: testState,
              onSeek: (pos) => seekTarget = pos,
              onUserInteraction: () {},
              onToggleFullscreen: () {},
            ),
          ),
        ),
      );

      // YouTube-style timecode: 04:12 / 1:48:30
      expect(find.textContaining('04:12'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      await tester.tap(find.byType(Slider));
      expect(seekTarget, isNotNull);
    });

    testWidgets('PlayerCenterControls renders Quick-Action Rewind, Play/Pause, Forward',
        (tester) async {
      bool playPauseTapped = false;
      Duration? seeked;

      const testState = AuraPlayerState(
        status: PlaybackStatus.playing,
        position: Duration(minutes: 5),
        duration: Duration(minutes: 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerCenterControls(
              state: testState,
              onPlayPause: () => playPauseTapped = true,
              onSeek: (pos) => seeked = pos,
              onUserInteraction: () {},
            ),
          ),
        ),
      );

      // Tap Play/Pause
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsNWidgets(3)); // [-10s, Pause, +10s]

      await tester.tap(iconButtons.at(1));
      expect(playPauseTapped, isTrue);

      // Tap Rewind (-10s)
      await tester.tap(iconButtons.at(0));
      expect(seeked, equals(const Duration(minutes: 4, seconds: 50)));

      // Tap Forward (+10s)
      await tester.tap(iconButtons.at(2));
      expect(seeked, equals(const Duration(minutes: 5, seconds: 10)));
    });

    testWidgets('PlayerCenterControls shows buffering spinner and handles 20s timeout with retry',
        (tester) async {
      bool retryPressed = false;

      const bufferingState = AuraPlayerState(
        status: PlaybackStatus.buffering,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerCenterControls(
              state: bufferingState,
              onPlayPause: () {},
              onSeek: (_) {},
              onUserInteraction: () {},
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Initially shows CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Fast forward past 20s timeout
      await tester.pump(const Duration(seconds: 21));

      // Now shows Retry button
      expect(find.text('Tap to Retry'), findsOneWidget);
      expect(find.text('Stream took too long to load.'), findsOneWidget);

      await tester.tap(find.text('Tap to Retry'));
      expect(retryPressed, isTrue);
    });
  });
}
