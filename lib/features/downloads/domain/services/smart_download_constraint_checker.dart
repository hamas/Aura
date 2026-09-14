import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Result of a [SmartDownloadConstraintChecker.check] call.
class ConstraintCheckResult {
  final bool canDownload;
  final String? blockedReason;

  const ConstraintCheckResult.allowed()
      : canDownload = true,
        blockedReason = null;

  const ConstraintCheckResult.blocked(this.blockedReason) : canDownload = false;
}

/// Encapsulates all runtime guardrails for the Smart Download engine.
///
/// Each dependency is injected so that tests can supply fakes without touching
/// platform channels.
class SmartDownloadConstraintChecker {
  final Connectivity _connectivity;
  final Battery _battery;

  /// Minimum battery level (inclusive) at which downloads are permitted.
  static const int _minBatteryPercent = 20;

  SmartDownloadConstraintChecker({
    Connectivity? connectivity,
    Battery? battery,
  })  : _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery();

  /// Returns [ConstraintCheckResult.allowed] only when ALL constraints pass:
  /// 1. Device is on unmetered Wi-Fi.
  /// 2. Battery level is above [_minBatteryPercent] OR device is charging.
  /// 3. Current vault usage is below [maxStorageBytes] - [lowStorageGuardBytes].
  Future<ConstraintCheckResult> check({
    required int currentVaultBytes,
    required int maxStorageBytes,
    required int lowStorageGuardBytes,
  }) async {
    // --- 1. Wi-Fi only policy ---
    final connectivityResults = await _connectivity.checkConnectivity();
    final isWifi = connectivityResults.contains(ConnectivityResult.wifi);
    if (!isWifi) {
      return const ConstraintCheckResult.blocked(
        'Smart Downloads require an unmetered Wi-Fi connection.',
      );
    }

    // --- 2. Battery threshold ---
    final batteryState = await _battery.batteryState;
    if (batteryState != BatteryState.charging &&
        batteryState != BatteryState.full) {
      final level = await _battery.batteryLevel;
      if (level < _minBatteryPercent) {
        return ConstraintCheckResult.blocked(
          'Smart Downloads paused: battery below $_minBatteryPercent% ($level%).',
        );
      }
    }

    // --- 3. Storage cap ---
    final usableMax = maxStorageBytes - lowStorageGuardBytes;
    if (currentVaultBytes >= usableMax) {
      final usedGb =
          (currentVaultBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      return ConstraintCheckResult.blocked(
        'Smart Downloads paused: vault at $usedGb GB — storage cap reached.',
      );
    }

    return const ConstraintCheckResult.allowed();
  }
}
