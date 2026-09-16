import 'package:aura/core/theme/aura_theme.dart';
import 'package:aura/features/addons/domain/entities/addon_manifest.dart';
import 'package:aura/features/addons/domain/entities/addon_stream.dart';
import 'package:aura/features/addons/domain/repositories/addon_repository.dart';
import 'package:aura/features/addons/presentation/bloc/addon_bloc.dart';
import 'package:aura/features/catalog/domain/entities/genre.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/domain/entities/person_details.dart';
import 'package:aura/features/catalog/domain/entities/season_episode.dart';
import 'package:aura/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:aura/features/catalog/presentation/screens/media_details_screen.dart';
import 'package:aura/features/downloads/domain/entities/download_task.dart';
import 'package:aura/features/downloads/domain/repositories/download_repository.dart';
import 'package:aura/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:aura/features/library/domain/entities/library_item.dart';
import 'package:aura/features/library/domain/repositories/library_repository.dart';
import 'package:aura/features/library/presentation/bloc/library_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCatalogRepository implements CatalogRepository {
  final MediaItem mediaItem;
  final Season season;

  FakeCatalogRepository({required this.mediaItem, required this.season});

  @override
  Future<List<MediaItem>> getTrending({String timeWindow = 'day'}) async =>
      [mediaItem];
  @override
  Future<List<MediaItem>> getTrendingMovies(
          {String timeWindow = 'day'}) async =>
      [mediaItem];
  @override
  Future<List<MediaItem>> getTrendingSeries(
          {String timeWindow = 'day'}) async =>
      [mediaItem];
  @override
  Future<List<MediaItem>> getPopularMovies({int page = 1}) async => [mediaItem];
  @override
  Future<List<MediaItem>> getPopularSeries({int page = 1}) async => [mediaItem];
  @override
  Future<List<MediaItem>> getNowPlayingMovies({int page = 1}) async =>
      [mediaItem];
  @override
  Future<List<MediaItem>> getOnTheAirSeries({int page = 1}) async =>
      [mediaItem];
  @override
  Future<List<MediaItem>> getInternationalHits({int page = 1}) async =>
      [mediaItem];
  @override
  Future<List<MediaItem>> searchMedia(String query, {int page = 1}) async =>
      [mediaItem];
  @override
  Future<MediaItem> getMediaDetails(int tmdbId, MediaType type) async =>
      mediaItem;
  @override
  Future<Season> getSeasonDetails(int tmdbSeriesId, int seasonNumber) async =>
      season;
  @override
  Future<List<Map<String, dynamic>>> getVideos(
          int tmdbId, MediaType type) async =>
      [
        {'key': 'mock_key', 'site': 'YouTube', 'type': 'Trailer'}
      ];
  @override
  Future<PersonDetails> getPersonDetails(int personId) async =>
      throw UnimplementedError();
}

class FakeLibraryRepository implements LibraryRepository {
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

class FakeAddonRepository implements AddonRepository {
  @override
  Future<AddonManifest> fetchManifest(String manifestUrl) async {
    return const AddonManifest(
      id: 'mock.addon',
      name: 'Mock Addon',
      version: '1.0.0',
      description: 'Mock addon for testing',
      transportUrl: 'https://example.com/manifest.json',
      resources: ['stream'],
      types: ['movie', 'series'],
      catalogs: [],
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
  Future<List<AddonStream>> getStreams({
    required String type,
    required String id,
  }) async =>
      [];
}

class FakeDownloadRepository implements DownloadRepository {
  @override
  Future<List<DownloadTask>> getAllDownloads() async => [];
  @override
  Stream<List<DownloadTask>> watchDownloads() => const Stream.empty();
  @override
  Future<void> startDownload(DownloadTask task) async {}
  @override
  Future<void> pauseDownload(String taskId) async {}
  @override
  Future<void> resumeDownload(String taskId) async {}
  @override
  Future<void> cancelDownload(String taskId) async {}
  @override
  Future<void> deleteDownload(String taskId) async {}
  @override
  Future<void> clearAllDownloads() async {}
  @override
  Future<int> getTotalStorageUsage() async => 0;
  @override
  Future<String> getSandboxedVaultDirectory() async => '/mock/vault';
  @override
  Future<DownloadTask?> getCompletedTask(int mediaId) async => null;
  @override
  Future<void> smartDeleteWatchedEpisode(
      int mediaId, int season, int episode) async {}
}

void main() {
  group('MediaDetailsScreen Widget Tests', () {
    const testCast = [
      CastMember(
        id: 1,
        name: 'Millie Bobby Brown',
        character: 'Eleven',
        profilePath: '/millie.jpg',
      ),
      CastMember(
        id: 2,
        name: 'Finn Wolfhard',
        character: 'Mike Wheeler',
        profilePath: '/finn.jpg',
      ),
    ];

    const testSeason = Season(
      id: 10,
      seasonNumber: 1,
      name: 'Season 1',
      overview: 'Strange things begin happening in Hawkins.',
      episodes: [
        Episode(
          id: 101,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Chapter One: The Vanishing',
          overview: 'A young boy vanishes near a secret government lab.',
          voteAverage: 8.8,
          runtimeMinutes: 48,
        ),
      ],
    );

    const testMediaItem = MediaItem(
      id: 999,
      imdbId: 'tt4574334',
      title: 'Stranger Things',
      tagline: 'Every ending has a beginning',
      overview:
          'When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces and one strange little girl. Together they battle the unknown.',
      posterPath: '/stranger_poster.jpg',
      backdropPath: '/stranger_backdrop.jpg',
      type: MediaType.series,
      voteAverage: 8.7,
      releaseDate: '2016-07-15',
      runtimeMinutes: 50,
      genres: [
        Genre(id: 1, name: 'Sci-Fi'),
        Genre(id: 2, name: 'Drama'),
        Genre(id: 3, name: 'Mystery'),
      ],
      cast: testCast,
      seasons: [testSeason],
    );

    Widget buildTestWidget({required MediaItem item}) {
      final catalogRepo = FakeCatalogRepository(
        mediaItem: item,
        season: testSeason,
      );
      final libraryRepo = FakeLibraryRepository();
      final addonRepo = FakeAddonRepository();
      final downloadRepo = FakeDownloadRepository();

      return MultiBlocProvider(
        providers: [
          BlocProvider<CatalogBloc>(
            create: (_) => CatalogBloc(catalogRepository: catalogRepo),
          ),
          BlocProvider<LibraryBloc>(
            create: (_) => LibraryBloc(libraryRepository: libraryRepo),
          ),
          BlocProvider<AddonBloc>(
            create: (_) => AddonBloc(addonRepository: addonRepo),
          ),
          BlocProvider<DownloadsBloc>(
            create: (_) => DownloadsBloc(downloadRepository: downloadRepo),
          ),
        ],
        child: MaterialApp(
          theme: AuraTheme.darkTheme,
          home: MediaDetailsScreen(
            id: item.id,
            type: item.type,
            initialItem: item,
          ),
        ),
      );
    }

    testWidgets('Renders title, metadata badges, and action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(item: testMediaItem));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Stranger Things'), findsOneWidget);
      expect(find.text('8.7'), findsOneWidget);
      expect(find.text('IMDb'), findsOneWidget);
      expect(find.text('2016'), findsOneWidget);
      expect(find.text('Watch'), findsOneWidget);
    });

    testWidgets('Renders synopsis text', (tester) async {
      await tester.pumpWidget(buildTestWidget(item: testMediaItem));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('When a young boy vanishes'), findsOneWidget);
    });

    testWidgets('Renders top cast actors and character labels', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(item: testMediaItem));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Millie Bobby Brown'), findsOneWidget);
      expect(find.text('Eleven'), findsOneWidget);
      expect(find.text('Finn Wolfhard'), findsOneWidget);
      expect(find.text('Mike Wheeler'), findsOneWidget);
    });

    testWidgets('Renders TV series season selector and episode card', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(item: testMediaItem));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Episodes'), findsOneWidget);
      expect(find.text('Season 1'), findsOneWidget);
    });
  });
}
