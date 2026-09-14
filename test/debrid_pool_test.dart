import 'package:aura/features/debrid/domain/entities/debrid_account.dart';
import 'package:aura/features/debrid/domain/providers/debrid_provider.dart';
import 'package:aura/features/debrid/domain/services/debrid_pool_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockDebridProvider implements DebridProvider {
  final DebridProviderType type;
  final bool hasToken;
  final Map<String, bool> availabilityMap;
  final bool shouldFail;

  MockDebridProvider({
    required this.type,
    this.hasToken = true,
    this.availabilityMap = const {},
    this.shouldFail = false,
  });

  @override
  DebridProviderType get providerType => type;

  @override
  String get name => type.displayName;

  @override
  String get tag => type.tag;

  @override
  Future<bool> hasValidToken() async => hasToken;

  @override
  Future<void> saveApiKey(String key) async {}

  @override
  Future<void> removeApiKey() async {}

  @override
  Future<DebridAccount> getUserInfo() async {
    if (shouldFail) throw Exception('Provider server timeout');
    return DebridAccount(
      providerType: type,
      username: '${type.displayName} User',
      email: 'user@${type.tag.toLowerCase()}.com',
      points: 500,
      type: 'premium',
      expirationDate: DateTime.now().add(const Duration(days: 15)),
    );
  }

  @override
  Future<Map<String, bool>> checkAvailability(List<String> infoHashes) async {
    if (shouldFail) throw Exception('Rate limit 429');
    final result = <String, bool>{};
    for (final hash in infoHashes) {
      result[hash] = availabilityMap[hash] ?? false;
    }
    return result;
  }

  @override
  Future<String> unrestrictLink(String magnetOrInfoHash,
      {int? fileIndex}) async {
    if (shouldFail) throw Exception('503 Service Unavailable');
    return 'https://${type.tag.toLowerCase()}.stream.download/$magnetOrInfoHash';
  }
}

void main() {
  group('Multi-Debrid Account Aggregator & Parallel Stream Pooling Tests', () {
    test('DebridPoolService queries active accounts in parallel', () async {
      final rd = MockDebridProvider(type: DebridProviderType.realDebrid);
      final ad = MockDebridProvider(type: DebridProviderType.allDebrid);
      final pm = MockDebridProvider(
          type: DebridProviderType.premiumize, hasToken: false);

      final pool = DebridPoolService(providers: [rd, ad, pm]);
      final activeAccounts = await pool.getActiveAccounts();

      expect(activeAccounts.length, equals(2));
      expect(
          activeAccounts
              .any((a) => a.providerType == DebridProviderType.realDebrid),
          isTrue);
      expect(
          activeAccounts
              .any((a) => a.providerType == DebridProviderType.allDebrid),
          isTrue);
    });

    test(
        'DebridPoolService dispatches parallel availability checks and tags provider results',
        () async {
      const hash1 = 'abc123hash';
      const hash2 = 'def456hash';

      final rd = MockDebridProvider(
        type: DebridProviderType.realDebrid,
        availabilityMap: {hash1: true, hash2: false},
      );
      final ad = MockDebridProvider(
        type: DebridProviderType.allDebrid,
        availabilityMap: {hash1: false, hash2: true},
      );

      final pool = DebridPoolService(providers: [rd, ad]);
      final pooledResults =
          await pool.checkAvailabilityInParallel([hash1, hash2]);

      expect(pooledResults.containsKey(hash1), isTrue);
      expect(pooledResults.containsKey(hash2), isTrue);

      final hash1Results = pooledResults[hash1]!;
      expect(
          hash1Results
              .firstWhere(
                  (r) => r.providerType == DebridProviderType.realDebrid)
              .isCached,
          isTrue);
      expect(
          hash1Results
              .firstWhere((r) => r.providerType == DebridProviderType.allDebrid)
              .isCached,
          isFalse);

      final hash2Results = pooledResults[hash2]!;
      expect(
          hash2Results
              .firstWhere((r) => r.providerType == DebridProviderType.allDebrid)
              .isCached,
          isTrue);
    });

    test(
        'DebridPoolService performs silent failover when a provider returns 429 or 503 errors',
        () async {
      final failingRd = MockDebridProvider(
        type: DebridProviderType.realDebrid,
        shouldFail: true,
      );
      final healthyAd = MockDebridProvider(
        type: DebridProviderType.allDebrid,
        availabilityMap: {'hash123': true},
      );

      final pool = DebridPoolService(providers: [failingRd, healthyAd]);

      // Should not throw despite failingRd errors
      final results = await pool.checkAvailabilityInParallel(['hash123']);
      expect(results['hash123']?.length, equals(1));
      expect(results['hash123']?.first.providerType,
          equals(DebridProviderType.allDebrid));

      final streamUrl = await pool.unrestrictWithFallback('hash123');
      expect(streamUrl, contains('ad.stream.download'));
    });
  });
}
