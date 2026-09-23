import '../entities/smart_download_settings.dart';

/// Repository contract for persisting and retrieving [SmartDownloadSettings].
abstract class SmartDownloadSettingsRepository {
  /// Loads the persisted settings. Returns defaults if none are stored yet.
  Future<SmartDownloadSettings> loadSettings();

  /// Persists [settings] to durable storage.
  Future<void> saveSettings(SmartDownloadSettings settings);
}
