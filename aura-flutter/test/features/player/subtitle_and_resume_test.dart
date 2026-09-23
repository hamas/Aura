import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/core/network/api_client.dart';
import 'package:aura/features/addons/data/datasources/stremio_addon_api.dart';
import 'package:aura/features/addons/domain/entities/addon_manifest.dart';
import 'package:aura/features/addons/domain/entities/addon_subtitle.dart';
import 'package:aura/features/player/data/services/media_kit_player_service.dart';
import 'package:aura/features/library/domain/entities/library_item.dart';
import 'package:aura/features/library/data/repositories/library_repository_impl.dart';

void main() {
  group('Stremio Subtitle Resolution & Playback Progress Continuity Tests', () {
    test('AddonSubtitle JSON deserialization & StremioAddonApi subtitle querying', () async {
      // 1. Test Subtitle model deserialization
      final json = {
        'id': 'sub_eng_1',
        'url': 'https://subtitles.example.com/en.srt',
        'lang': 'eng',
      };
      final sub = AddonSubtitle.fromJson(json);
      expect(sub.id, equals('sub_eng_1'));
      expect(sub.url, equals('https://subtitles.example.com/en.srt'));
      expect(sub.lang, equals('eng'));

      // 2. Mock StremioAddonApi subtitle endpoint response
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        if (options.path.contains('/subtitles/movie/tt0137523.json')) {
          return ResponseBody.fromString(
            '{"subtitles":[{"id":"sub_1","url":"https://sub.test/1.vtt","lang":"eng"},{"id":"sub_2","url":"https://sub.test/2.srt","lang":"spa"}]}',
            200,
            headers: {'content-type': ['application/json']},
          );
        }
        return ResponseBody.fromString('{}', 404);
      });

      final api = StremioAddonApi(apiClient: ApiClient(dio: dio));
      const manifest = AddonManifest(
        id: 'opensubtitles',
        name: 'OpenSubtitles v3',
        version: '1.0.0',
        description: 'Official OpenSubtitles',
        transportUrl: 'https://opensubtitles.strem.io/manifest.json',
        resources: ['subtitles'],
        types: ['movie', 'series'],
      );

      final fetchedSubs = await api.fetchSubtitles(
        manifest: manifest,
        type: 'movie',
        id: 'tt0137523',
      );

      // Verify that sub tracks are returned and parsed
      expect(fetchedSubs, isNotEmpty);
      expect(fetchedSubs.first.lang, equals('eng'));
    });

    test('MediaKitPlayerService registers external subtitle tracks correctly', () async {
      final playerService = MediaKitPlayerService.test();

      await playerService.addExternalSubtitleTrack(
        url: 'https://sub.example.com/fr.vtt',
        language: 'fre',
        title: 'FRE (Addon)',
      );

      final tracks = playerService.state.subtitleTracks;
      expect(tracks, isNotEmpty);

      final extTrack = tracks.firstWhere((t) => t.isExternal);
      expect(extTrack.isExternal, isTrue);
      expect(extTrack.uri, equals('https://sub.example.com/fr.vtt'));
      expect(extTrack.language, equals('fre'));

      // Test selecting external track
      await playerService.selectSubtitleTrack(extTrack);
      expect(playerService.state.selectedSubtitleTrack, equals(extTrack));
    });

    test('LibraryRepositoryImpl watch progress calculation & continuation threshold', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final libraryRepo = LibraryRepositoryImpl(prefs: prefs);

      // Save watch progress at 50% (600s / 1200s)
      await libraryRepo.updateWatchProgress(
        mediaId: 'movie_550',
        title: 'Inception',
        posterPath: '/inception.jpg',
        backdropPath: '/inception_bg.jpg',
        type: 'movie',
        positionSeconds: 600,
        durationSeconds: 1200,
      );

      final items = await libraryRepo.getLibraryItems(
        category: LibraryCategory.continueWatching,
      );

      expect(items, isNotEmpty);
      final item = items.firstWhere((i) => i.id == 'movie_550');
      expect(item.progress, isNotNull);
      expect(item.progress!.positionSeconds, equals(600));
      expect(item.progress!.percentage, equals(0.5));
      expect(item.progress!.isFinished, isFalse);

      // Verify resume eligibility (>15s and <92%)
      final posSec = item.progress!.positionSeconds;
      final durSec = item.progress!.durationSeconds;
      final isResumeEligible = posSec > 15 && posSec < (durSec * 0.92);
      expect(isResumeEligible, isTrue);
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  _MockHttpClientAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
