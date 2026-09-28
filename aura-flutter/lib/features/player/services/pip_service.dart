import 'package:flutter/services.dart';

/// Service managing Picture-in-Picture (PiP) lifecycle across Android devices,
/// including Android 14+ predictive back gesture auto-PiP and aspect ratio scaling.
class PipService {
  static const MethodChannel _channel = MethodChannel('aura/pip');

  /// Attempts to enter Picture-in-Picture mode on Android devices.
  static Future<bool> enterPip({
    double aspectRatio = 16 / 9,
    bool autoEnterOnBackground = true,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'enterPip',
        {
          'aspectRatio': aspectRatio,
          'autoEnterOnBackground': autoEnterOnBackground,
        },
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Registers auto-PiP params with Android Activity for predictive back gesture navigation.
  static Future<void> setAutoPipParams({
    required bool enabled,
    double aspectRatio = 16 / 9,
  }) async {
    try {
      await _channel.invokeMethod('setAutoPipParams', {
        'enabled': enabled,
        'aspectRatio': aspectRatio,
      });
    } catch (_) {}
  }

  /// Checks if PiP mode is currently active.
  static Future<bool> isPipActive() async {
    try {
      final bool? active = await _channel.invokeMethod<bool>('isPipActive');
      return active ?? false;
    } catch (_) {
      return false;
    }
  }
}
