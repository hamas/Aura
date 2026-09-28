import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service managing Android TV / Google TV / FireTV 10-foot navigation,
/// home screen recommendations channels, and Google Assistant voice search intents.
class TvNavigationService {
  const TvNavigationService._();

  static const MethodChannel _tvChannel = MethodChannel('aura/tv_launcher');

  /// Detects whether the current device is running in Android TV mode.
  static bool get isTvMode {
    if (kIsWeb) return false;
    return Platform.isAndroid &&
        (const bool.fromEnvironment('TV_MODE', defaultValue: false) ||
            _isAndroidTvDevice());
  }

  static bool _isAndroidTvDevice() {
    // In release/debug APKs, TV_MODE or UI mode type TELEVISION triggers TV optimizations
    return const bool.fromEnvironment('TV_MODE', defaultValue: false);
  }

  static double get textScaleFactor => isTvMode ? 1.15 : 1.0;

  /// Publishes continue-watching and trending programs to the Android TV Home Screen Channel.
  static Future<void> syncHomeScreenChannel({
    required List<Map<String, dynamic>> recommendedItems,
  }) async {
    if (!isTvMode) return;
    try {
      await _tvChannel.invokeMethod('syncChannelPrograms', {
        'channelName': 'Aura Featured & Trending',
        'programs': recommendedItems,
      });
    } catch (_) {}
  }

  /// Sets up Google Assistant global search intent listener for voice queries.
  static void registerVoiceSearchHandler(void Function(String query) onQueryReceived) {
    if (!isTvMode) return;
    _tvChannel.setMethodCallHandler((call) async {
      if (call.method == 'onVoiceSearchQuery') {
        final query = call.arguments as String?;
        if (query != null && query.isNotEmpty) {
          onQueryReceived(query);
        }
      }
    });
  }
}
