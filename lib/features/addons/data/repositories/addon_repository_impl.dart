import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/addon_manifest.dart';
import '../../domain/entities/addon_stream.dart';
import '../../domain/repositories/addon_repository.dart';
import '../datasources/stremio_addon_api.dart';

class AddonRepositoryImpl implements AddonRepository {
  final StremioAddonApi _addonApi;
  final SharedPreferences _prefs;

  static const String _keyInstalledAddons = 'aura_installed_addons_v1';
  static const List<String> defaultManifestUrls = [
    ApiConstants.defaultCinemetaUrl,
    'https://opensubtitles-v3.strem.io/manifest.json',
  ];

  AddonRepositoryImpl({
    StremioAddonApi? addonApi,
    required SharedPreferences prefs,
  })  : _addonApi = addonApi ?? StremioAddonApi(),
        _prefs = prefs;

  @override
  Future<AddonManifest> fetchManifest(String manifestUrl) {
    return _addonApi.fetchManifest(manifestUrl);
  }

  @override
  Future<List<AddonManifest>> getInstalledAddons() async {
    final rawList = _prefs.getStringList(_keyInstalledAddons);
    if (rawList == null || rawList.isEmpty) {
      // Setup default official community add-ons if none installed
      const defaultCinemeta = AddonManifest(
        id: 'com.linvo.cinemeta',
        name: 'Cinemeta (Official)',
        version: '3.0.12',
        description: 'Official movie & TV show metadata catalog',
        transportUrl: ApiConstants.defaultCinemetaUrl,
        resources: ['catalog', 'meta'],
        types: ['movie', 'series'],
        isEnabled: true,
      );

      const defaultOpenSubtitles = AddonManifest(
        id: 'org.stremio.opensubtitles-v3',
        name: 'OpenSubtitles v3 (Official)',
        version: '1.0.0',
        description: 'Official OpenSubtitles v3 community subtitle provider',
        transportUrl: 'https://opensubtitles-v3.strem.io/manifest.json',
        resources: ['subtitles'],
        types: ['movie', 'series'],
        isEnabled: true,
      );

      final defaults = [defaultCinemeta, defaultOpenSubtitles];
      for (final addon in defaults) {
        await installAddon(addon);
      }
      return defaults;
    }

    return rawList.map((str) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return AddonManifest.fromJson(map, transportUrl: map['transportUrl'] as String? ?? '');
    }).toList();
  }

  @override
  Future<void> installAddon(AddonManifest manifest) async {
    final current = await getInstalledAddons();
    final updated = List<AddonManifest>.from(current)
      ..removeWhere((a) => a.id == manifest.id)
      ..add(manifest);

    final rawJsonList = updated.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_keyInstalledAddons, rawJsonList);
  }

  @override
  Future<void> uninstallAddon(String addonId) async {
    final current = await getInstalledAddons();
    final updated = current.where((a) => a.id != addonId).toList();
    final rawJsonList = updated.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_keyInstalledAddons, rawJsonList);
  }

  @override
  Future<void> toggleAddonStatus(String addonId, bool isEnabled) async {
    final current = await getInstalledAddons();
    final updated = current.map((a) {
      if (a.id == addonId) {
        return a.copyWith(isEnabled: isEnabled);
      }
      return a;
    }).toList();

    final rawJsonList = updated.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_keyInstalledAddons, rawJsonList);
  }

  @override
  Future<List<AddonStream>> getStreams({
    required String type,
    required String id,
  }) async {
    final addons = await getInstalledAddons();
    final enabledAddons = addons.where((a) => a.isEnabled).toList();

    // Query streams concurrently across all active add-ons
    final streamFutures = enabledAddons.map((addon) {
      return _addonApi.fetchStreams(manifest: addon, type: type, id: id);
    });

    final streamResults = await Future.wait(streamFutures);
    final aggregatedStreams = <AddonStream>[];

    for (final list in streamResults) {
      aggregatedStreams.addAll(list);
    }

    return aggregatedStreams;
  }
}
