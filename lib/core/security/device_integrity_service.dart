import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility service to verify device security, root/jailbreak indicators, and emulator environment.
class DeviceIntegrityService {
  static const MethodChannel _channel = MethodChannel('com.aura.app/integrity');

  /// Check if running in a release build on a known emulator or compromised environment.
  static Future<bool> isEnvironmentCompromised() async {
    if (kIsWeb) return false;

    // Check basic known root file indicators on Android
    if (Platform.isAndroid) {
      const knownRootPaths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
      ];

      for (final path in knownRootPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }
    }

    // Check basic known jailbreak paths on iOS
    if (Platform.isIOS) {
      const knownJailbreakPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
      ];

      for (final path in knownJailbreakPaths) {
        if (File(path).existsSync()) {
          return true;
        }
      }
    }

    try {
      final bool? isCompromised = await _channel.invokeMethod<bool>('checkIntegrity');
      return isCompromised ?? false;
    } catch (_) {
      return false;
    }
  }
}
