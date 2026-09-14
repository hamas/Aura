import 'package:flutter/services.dart';

class PipService {
  static const MethodChannel _channel = MethodChannel('aura/pip');

  /// Attempts to enter Picture-in-Picture mode on Android devices.
  static Future<bool> enterPip({double aspectRatio = 16 / 9}) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'enterPip',
        {'aspectRatio': aspectRatio},
      );
      return success ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
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
