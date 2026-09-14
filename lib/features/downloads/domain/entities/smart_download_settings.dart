import 'package:equatable/equatable.dart';

/// Immutable settings object controlling Smart Download behaviour for a series.
///
/// Persisted via [SharedPreferences] keyed by [SmartDownloadSettingsRepository].
class SmartDownloadSettings extends Equatable {
  /// Whether Smart Downloads auto-management is enabled for this device.
  final bool enabled;

  /// Number of upcoming episodes to keep ready ahead of the cursor (1–3).
  final int bufferSize;

  /// Maximum total vault storage the engine is allowed to occupy, in bytes.
  /// Default: 15 GB.
  final int maxStorageBytes;

  /// Minimum free vault head-room before the engine stops queuing, in bytes.
  /// Default: 2 GB.
  final int lowStorageGuardBytes;

  const SmartDownloadSettings({
    this.enabled = false,
    this.bufferSize = 2,
    this.maxStorageBytes = 15 * 1024 * 1024 * 1024,
    this.lowStorageGuardBytes = 2 * 1024 * 1024 * 1024,
  });

  SmartDownloadSettings copyWith({
    bool? enabled,
    int? bufferSize,
    int? maxStorageBytes,
    int? lowStorageGuardBytes,
  }) {
    return SmartDownloadSettings(
      enabled: enabled ?? this.enabled,
      bufferSize: (bufferSize ?? this.bufferSize).clamp(1, 3),
      maxStorageBytes: maxStorageBytes ?? this.maxStorageBytes,
      lowStorageGuardBytes: lowStorageGuardBytes ?? this.lowStorageGuardBytes,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'bufferSize': bufferSize,
        'maxStorageBytes': maxStorageBytes,
        'lowStorageGuardBytes': lowStorageGuardBytes,
      };

  factory SmartDownloadSettings.fromJson(Map<String, dynamic> json) {
    return SmartDownloadSettings(
      enabled: json['enabled'] as bool? ?? false,
      bufferSize: ((json['bufferSize'] as int?) ?? 2).clamp(1, 3),
      maxStorageBytes: json['maxStorageBytes'] as int? ?? 15 * 1024 * 1024 * 1024,
      lowStorageGuardBytes: json['lowStorageGuardBytes'] as int? ?? 2 * 1024 * 1024 * 1024,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        bufferSize,
        maxStorageBytes,
        lowStorageGuardBytes,
      ];
}
