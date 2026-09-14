import '../entities/debrid_account.dart';
import '../providers/debrid_provider.dart';
import '../providers/all_debrid_provider_impl.dart';
import '../providers/premiumize_torbox_providers_impl.dart';
import '../providers/real_debrid_provider_impl.dart';

class PooledStreamResult {
  final String infoHash;
  final bool isCached;
  final DebridProviderType providerType;

  const PooledStreamResult({
    required this.infoHash,
    required this.isCached,
    required this.providerType,
  });
}

class DebridPoolService {
  final List<DebridProvider> _providers;

  DebridPoolService({List<DebridProvider>? providers})
      : _providers = providers ??
            [
              RealDebridProviderImpl(),
              AllDebridProviderImpl(),
              PremiumizeProviderImpl(),
              TorBoxProviderImpl(),
            ];

  List<DebridProvider> get providers => List.unmodifiable(_providers);

  /// Fetch user account info across all authenticated providers in parallel
  Future<List<DebridAccount>> getActiveAccounts() async {
    final activeAccounts = <DebridAccount>[];
    final futures = _providers.map((p) async {
      try {
        if (await p.hasValidToken()) {
          final account = await p.getUserInfo();
          return account;
        }
      } catch (_) {}
      return null;
    });

    final results = await Future.wait(futures);
    for (final acc in results) {
      if (acc != null) activeAccounts.add(acc);
    }
    return activeAccounts;
  }

  /// Perform parallel hash availability checking across all linked providers
  Future<Map<String, List<PooledStreamResult>>> checkAvailabilityInParallel(
      List<String> infoHashes) async {
    final pooledMap = <String, List<PooledStreamResult>>{};

    final futures = _providers.map((provider) async {
      try {
        if (await provider.hasValidToken()) {
          final res = await provider.checkAvailability(infoHashes);
          return MapEntry(provider, res);
        }
      } catch (_) {
        // Silent failover on rate limit / server error
      }
      return null;
    });

    final results = await Future.wait(futures);

    for (final entry in results) {
      if (entry == null) continue;
      final provider = entry.key;
      final availability = entry.value;

      availability.forEach((hash, isCached) {
        pooledMap.putIfAbsent(hash, () => []).add(
              PooledStreamResult(
                infoHash: hash,
                isCached: isCached,
                providerType: provider.providerType,
              ),
            );
      });
    }

    return pooledMap;
  }

  /// Unrestrict stream with automatic provider fallback
  Future<String> unrestrictWithFallback(
    String magnetOrInfoHash, {
    int? fileIndex,
    DebridProviderType? preferredProvider,
  }) async {
    final activeProviders = <DebridProvider>[];
    for (final p in _providers) {
      if (await p.hasValidToken()) {
        activeProviders.add(p);
      }
    }

    if (activeProviders.isEmpty) {
      // Fallback default Real-Debrid unrestrict attempt
      final defaultRd = RealDebridProviderImpl();
      return defaultRd.unrestrictLink(magnetOrInfoHash, fileIndex: fileIndex);
    }

    if (preferredProvider != null) {
      activeProviders.sort((a, b) {
        if (a.providerType == preferredProvider) return -1;
        if (b.providerType == preferredProvider) return 1;
        return 0;
      });
    }

    final List<Object> errors = [];
    for (final provider in activeProviders) {
      try {
        final link = await provider.unrestrictLink(magnetOrInfoHash,
            fileIndex: fileIndex);
        return link;
      } catch (e) {
        errors.add(e);
      }
    }

    throw Exception(
        'Failed to unrestrict link across all active providers: $errors');
  }
}
