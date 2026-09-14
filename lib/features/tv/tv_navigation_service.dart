import 'dart:io';
import 'package:flutter/foundation.dart';

class TvNavigationService {
  const TvNavigationService._();

  static bool get isTvMode {
    if (kIsWeb) return false;
    // Basic platform detection check for Android TV mode
    return Platform.isAndroid &&
        const bool.fromEnvironment('TV_MODE', defaultValue: false);
  }

  static double get textScaleFactor => isTvMode ? 1.15 : 1.0;
}
