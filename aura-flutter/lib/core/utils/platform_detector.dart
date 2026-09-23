import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformDetector {
  PlatformDetector._();

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get isWeb => kIsWeb;

  /// App Store compliance: BitTorrent/P2P capabilities are strictly disallowed on iOS.
  static bool get supportsP2PStreaming => isAndroid || (isDesktop && !isIOS);
}
