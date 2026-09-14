import 'package:aura/core/theme/aura_theme.dart';
import 'package:aura/features/addons/domain/entities/addon_manifest.dart';
import 'package:aura/features/addons/domain/entities/addon_stream.dart';
import 'package:aura/features/addons/domain/repositories/addon_repository.dart';
import 'package:aura/features/addons/presentation/bloc/addon_bloc.dart';
import 'package:aura/features/catalog/domain/entities/genre.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/domain/entities/season_episode.dart';
import 'package:aura/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura/features/clips/data/repositories/clips_repository_impl.dart';
import 'package:aura/features/clips/domain/entities/clip_item.dart';
import 'package:aura/features/clips/presentation/bloc/clips_bloc.dart';
import 'package:aura/features/clips/presentation/bloc/clips_event.dart';
import 'package:aura/features/clips/presentation/bloc/clips_state.dart';
import 'package:aura/features/clips/presentation/screens/clips_screen.dart';
import 'package:aura/features/library/domain/entities/library_item.dart';
import 'package:aura/features/library/domain/repositories/library_repository.dart';
import 'package:aura/features/library/presentation/bloc/library_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockCatalogRepository implements CatalogRepository {
  final List<MediaItem> items;

  MockCatalogRepository({required this.items});

  @override
  Future<List<MediaItem>> getTrending({String timeWindow = 'day'}) async =>
      items;
  @override
  Future<List<MediaItem>> getTrendingMovies(
          {String timeWindow = 'day'}) async =>
      items;
  @override
  Future<List<MediaItem>> getTrendingSeries(
          {String timeWindow = 'day'}) async =>
      items;
  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => items;
  @override
  Future<List<MediaItem>> getPopularSeries({int page = 1}) async => items;
  @override
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async =>
      items;
  @override
  Future<MediaItem> getMediaDetails(int tmdbId, MediaType type) async =>
      items.first;
  @override
  Future<Season> getSeasonDetails(int tmdbSeriesId, int seasonNumber) async =>
      const Season(id: 1, seasonNumber: 1, name: 'S1', overview: '');
  @override
  Future<List<Map<String, dynamic>>> getVideos(
          int tmdbId, MediaType type) async =>
      [
        {'key': 'mock_trailer_key', 'site': 'YouTube', 'type': 'Trailer'}
      ];
}

class MockLibraryRepository implements LibraryRepository {
  List<LibraryItem> items = [];

  @override
  Future<List<LibraryItem>> getLibraryItems(
          {LibraryCategory? category}) async =>
      items;
  @override
  Future<void> saveLibraryItem(LibraryItem item) async => items.add(item);
  @override
  Future<void> updateWatchProgress({
    required String mediaId,
    required String title,
    required String? posterPath,
    required String? backdropPath,
    required String type,
    required int positionSeconds,
    required int durationSeconds,
    int? seasonNumber,
    int? episodeNumber,
  }) async {}
  @override
  Future<void> removeItem(String mediaId) async =>
      items.removeWhere((i) => i.id == mediaId);
  @override
  Future<void> syncWithCloud() async {}
}

class MockAddonRepository implements AddonRepository {
  @override
  Future<AddonManifest> fetchManifest(String manifestUrl) async {
    return const AddonManifest(
      id: 'mock',
      name: 'Mock',
      version: '1.0.0',
      description: '',
      transportUrl: 'https://example.com/manifest.json',
      resources: ['stream'],
      types: ['movie', 'series'],
    );
  }

  @override
  Future<List<AddonManifest>> getInstalledAddons() async => [];
  @override
  Future<void> installAddon(AddonManifest manifest) async {}
  @override
  Future<void> uninstallAddon(String addonId) async {}
  @override
  Future<void> toggleAddonStatus(String addonId, bool isEnabled) async {}
  @override
  Future<List<AddonStream>> getStreams(
          {required String type, required String id}) async =>
      [];
}

void main() {
  group('Full-Screen Clips Engine Unit & Widget Tests', () {
    const sampleMedia = MediaItem(
      id: 550,
      title: 'Fight Club',
      overview:
          'An insomniac office worker and a devil-may-care soap maker form an underground fight club.',
      posterPath: '/poster.jpg',
      backdropPath: '/backdrop.jpg',
      type: MediaType.movie,
      voteAverage: 8.8,
      releaseDate: '1999-10-15',
      genres: [Genre(id: 1, name: 'Drama')],
    );

    const sampleClip = ClipItem(
      id: 'clip_movie_550',
      mediaId: 550,
      title: 'Fight Club',
      overview:
          'An insomniac office worker and a devil-may-care soap maker form an underground fight club.',
      videoKey: 'mock_trailer_key',
      posterPath: '/poster.jpg',
      backdropPath: '/backdrop.jpg',
      voteAverage: 8.8,
      releaseYear: '1999',
      mediaType: MediaType.movie,
      genres: ['Drama'],
      mediaItem: sampleMedia,
    );

    test('ClipItem calculates formatted rating and URL getters correctly', () {
      expect(sampleClip.formattedRating, equals('8.8'));
      expect(sampleClip.fullBackdropUrl, contains('/backdrop.jpg'));
      expect(sampleClip.fullPosterUrl, contains('/poster.jpg'));
    });

    test('ClipsRepositoryImpl aggregates trending clips with video keys',
        () async {
      final mockCatalog = MockCatalogRepository(items: [sampleMedia]);
      final clipsRepo = ClipsRepositoryImpl(catalogRepository: mockCatalog);

      final clips = await clipsRepo.getTrendingClips();
      expect(clips.isNotEmpty, isTrue);
      expect(clips.first.title, equals('Fight Club'));
      expect(clips.first.videoKey, equals('mock_trailer_key'));
    });

    test('ClipsBloc handles load, index change, like toggle, and mute toggle',
        () async {
      final mockCatalog = MockCatalogRepository(items: [sampleMedia]);
      final clipsRepo = ClipsRepositoryImpl(catalogRepository: mockCatalog);
      final bloc = ClipsBloc(clipsRepository: clipsRepo);

      expect(bloc.state.status, equals(ClipsStatus.initial));

      bloc.add(LoadClipsEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const ClipsState(status: ClipsStatus.loading),
          predicate<ClipsState>(
              (s) => s.status == ClipsStatus.success && s.clips.isNotEmpty),
        ]),
      );

      bloc.add(const ChangeActiveClipIndexEvent(0));
      await Future<void>.delayed(Duration.zero);

      bloc.add(ToggleClipMuteEvent());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.isMuted, isTrue);

      bloc.add(const ToggleClipLikeEvent('clip_movie_550'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.likedClipIds.contains('clip_movie_550'), isTrue);
    });

    testWidgets(
        'ClipsScreen renders vertical page item with metadata and action buttons',
        (
      tester,
    ) async {
      final mockCatalog = MockCatalogRepository(items: [sampleMedia]);
      final clipsRepo = ClipsRepositoryImpl(catalogRepository: mockCatalog);
      final libraryRepo = MockLibraryRepository();
      final addonRepo = MockAddonRepository();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ClipsBloc>(
              create: (_) => ClipsBloc(clipsRepository: clipsRepo),
            ),
            BlocProvider<LibraryBloc>(
              create: (_) => LibraryBloc(libraryRepository: libraryRepo),
            ),
            BlocProvider<AddonBloc>(
              create: (_) => AddonBloc(addonRepository: addonRepo),
            ),
          ],
          child: MaterialApp(
            theme: AuraTheme.darkTheme,
            home: const ClipsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fight Club'), findsOneWidget);
      expect(find.text('8.8'), findsOneWidget);
      expect(find.text('4K HDR'), findsOneWidget);
      expect(find.text('MOVIE'), findsOneWidget);
      expect(find.text('My List'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
    });
  });
}
