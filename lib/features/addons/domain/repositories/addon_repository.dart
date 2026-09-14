import '../entities/addon_manifest.dart';
import '../entities/addon_stream.dart';

abstract class AddonRepository {
  /// Fetches the manifest from a remote URL.
  Future<AddonManifest> fetchManifest(String manifestUrl);

  /// Returns list of all installed add-ons.
  Future<List<AddonManifest>> getInstalledAddons();

  /// Installs an add-on from manifest.
  Future<void> installAddon(AddonManifest manifest);

  /// Uninstalls an add-on by id.
  Future<void> uninstallAddon(String addonId);

  /// Toggles add-on active state.
  Future<void> toggleAddonStatus(String addonId, bool isEnabled);

  /// Aggregates streams from all enabled add-ons for a given media (e.g. IMDb ID `tt0137523` or `tt0944947:1:1`).
  Future<List<AddonStream>> getStreams({
    required String type,
    required String id,
  });
}
