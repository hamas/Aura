import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/smart_download_settings.dart';
import '../../domain/repositories/smart_download_settings_repository.dart';

class SmartDownloadSettingsRepositoryImpl
    implements SmartDownloadSettingsRepository {
  static const String _prefKey = 'aura_smart_download_settings_v1';

  final SharedPreferences _prefs;

  SmartDownloadSettingsRepositoryImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  @override
  Future<SmartDownloadSettings> loadSettings() async {
    final raw = _prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) {
      return const SmartDownloadSettings();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SmartDownloadSettings.fromJson(json);
    } catch (_) {
      return const SmartDownloadSettings();
    }
  }

  @override
  Future<void> saveSettings(SmartDownloadSettings settings) async {
    await _prefs.setString(_prefKey, jsonEncode(settings.toJson()));
  }
}
