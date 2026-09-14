import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/addons/data/repositories/addon_repository_impl.dart';
import 'package:aura/features/debrid/domain/entities/debrid_account.dart';
import 'package:aura/features/library/domain/entities/library_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 - Debrid Engine, Add-on Ecosystem & Cloud Sync Tests', () {
    test(
        'DebridAccount entity correctly deserializes and evaluates premium status',
        () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 45));

      final json = {
        'id': 123456,
        'username': 'aura_tester',
        'email': 'tester@aura.app',
        'points': 850,
        'type': 'premium',
        'premium': 45 * 86400,
        'expiration': futureDate.toIso8601String(),
      };

      final account = DebridAccount.fromJson(json);

      expect(account.username, equals('aura_tester'));
      expect(account.isPremium, isTrue);
      expect(account.premiumDaysLeft, greaterThanOrEqualTo(44));
    });

    test(
        'WatchProgress calculates viewing percentage and completion threshold accurately',
        () {
      final progressInProgress = WatchProgress(
        positionSeconds: 1200,
        durationSeconds: 3600,
        lastWatchedAt: DateTime.now(),
      );

      expect(progressInProgress.percentage, closeTo(0.333, 0.01));
      expect(progressInProgress.isFinished, isFalse);

      final progressFinished = WatchProgress(
        positionSeconds: 3400,
        durationSeconds: 3600,
        lastWatchedAt: DateTime.now(),
      );

      expect(progressFinished.percentage, greaterThan(0.90));
      expect(progressFinished.isFinished, isTrue);
    });

    test(
        'AddonRepositoryImpl provides community default manifests on first launch',
        () {
      const defaultManifests = AddonRepositoryImpl.defaultManifestUrls;

      expect(defaultManifests,
          contains('https://v3-cinemeta.strem.io/manifest.json'));
      expect(defaultManifests,
          contains('https://opensubtitles-v3.strem.io/manifest.json'));
    });

    test('LibraryItem serializes and deserializes cleanly with progress', () {
      final item = LibraryItem(
        id: 'tt0137523',
        title: 'Fight Club',
        type: 'movie',
        category: LibraryCategory.continueWatching,
        posterPath: '/path.jpg',
        backdropPath: '/backdrop.jpg',
        progress: WatchProgress(
          positionSeconds: 1500,
          durationSeconds: 8400,
          lastWatchedAt: DateTime.parse('2026-09-14T12:00:00Z'),
        ),
        updatedAt: DateTime.parse('2026-09-14T12:00:00Z'),
      );

      final json = item.toJson();
      final restored = LibraryItem.fromJson(json);

      expect(restored.id, equals('tt0137523'));
      expect(restored.title, equals('Fight Club'));
      expect(restored.category, equals(LibraryCategory.continueWatching));
      expect(restored.progress?.positionSeconds, equals(1500));
      expect(restored.progress?.isFinished, isFalse);
    });
  });
}
