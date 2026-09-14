import 'package:aura/core/theme/aura_theme.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/presentation/widgets/widgets.dart';
import 'package:aura/features/library/domain/entities/library_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cinematic Design System Tokens & Geometry', () {
    test('Aura theme tokens match Netflix dark aesthetic and brand accent', () {
      expect(AppColors.surfaceBackground, equals(const Color(0xFF141414)));
      expect(AppColors.surfaceCard, equals(const Color(0xFF1F1F1F)));
      expect(AppColors.surfaceElevated, equals(const Color(0xFF262626)));
      expect(AppColors.accentPink, equals(const Color(0xFFB877FF)));
      expect(AppColors.textPrimary, equals(const Color(0xFFF5F5F7)));
      expect(AppTokens.posterAspectRatio, equals(2 / 3));
      expect(AppTokens.backdropAspectRatio, equals(16 / 9));
      expect(AppTokens.radiusSmall, equals(4.0));
      expect(AppTokens.focusScaleFactor, equals(1.06));
    });

    test('AuraTheme darkTheme generates valid Material 3 dark ThemeData', () {
      final theme = AuraTheme.darkTheme;
      expect(theme.brightness, equals(Brightness.dark));
      expect(
          theme.scaffoldBackgroundColor, equals(AppColors.surfaceBackground));
      expect(theme.colorScheme.primary, equals(AppColors.accentPink));
    });
  });

  group('Cinematic Widgets Component Suite', () {
    const testMedia = MediaItem(
      id: 101,
      title: 'Stranger Things',
      overview: 'When a young boy vanishes, a small town uncovers a mystery.',
      posterPath: '/poster.jpg',
      backdropPath: '/backdrop.jpg',
      type: MediaType.series,
      voteAverage: 8.7,
      releaseDate: '2022-05-27',
      tagline: 'Every ending has a beginning',
    );

    final testLibraryItem = LibraryItem(
      id: '101',
      title: 'Stranger Things',
      posterPath: '/poster.jpg',
      backdropPath: '/backdrop.jpg',
      type: 'series',
      category: LibraryCategory.continueWatching,
      progress: WatchProgress(
        positionSeconds: 1800,
        durationSeconds: 3600,
        seasonNumber: 4,
        episodeNumber: 1,
        lastWatchedAt: DateTime(2026, 1, 1),
      ),
      updatedAt: DateTime(2026, 1, 1),
    );

    testWidgets('MediaPosterCard renders title and rating with 2:3 ratio', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: const Scaffold(
            body: MediaPosterCard(item: testMedia),
          ),
        ),
      );

      expect(find.text('Stranger Things'), findsOneWidget);
      expect(find.text('8.7'), findsOneWidget);
      expect(find.text('2022'), findsOneWidget);
    });

    testWidgets('ContinueWatchingCard renders progress and episode badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: ContinueWatchingCard(item: testLibraryItem),
          ),
        ),
      );

      expect(find.text('Stranger Things'), findsOneWidget);
      expect(find.text('S4:E1'), findsOneWidget);
      expect(find.text('30m remaining'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('BillboardHeroBanner renders action buttons and metadata', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: const Scaffold(
            body: BillboardHeroBanner(
              items: [testMedia],
              autoScroll: false,
            ),
          ),
        ),
      );

      expect(
          find.text('STRANGER THINGS'), findsNothing); // tagline is uppercase
      expect(find.text('EVERY ENDING HAS A BEGINNING'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('4K HDR'), findsOneWidget);
      expect(find.text('SERIES'), findsOneWidget);
    });

    testWidgets('HorizontalContentShelf renders section header and posters', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AuraTheme.darkTheme,
          home: Scaffold(
            body: HorizontalContentShelf.media(
              title: 'Trending Now',
              subtitle: 'Top worldwide cinema',
              items: const [testMedia],
            ),
          ),
        ),
      );

      expect(find.text('Trending Now'), findsOneWidget);
      expect(find.text('Top worldwide cinema'), findsOneWidget);
      expect(find.byType(MediaPosterCard), findsOneWidget);
    });
  });
}
