import 'package:equatable/equatable.dart';
import '../../domain/entities/addon_manifest.dart';
import '../../domain/entities/addon_stream.dart';

enum AddonStatus { initial, loading, success, failure }

class AddonState extends Equatable {
  final AddonStatus status;
  final List<AddonManifest> installedAddons;
  final List<AddonStream> resolvedStreams;
  final bool isLoadingStreams;
  final String? errorMessage;
  final String? successMessage;

  const AddonState({
    this.status = AddonStatus.initial,
    this.installedAddons = const [],
    this.resolvedStreams = const [],
    this.isLoadingStreams = false,
    this.errorMessage,
    this.successMessage,
  });

  AddonState copyWith({
    AddonStatus? status,
    List<AddonManifest>? installedAddons,
    List<AddonStream>? resolvedStreams,
    bool? isLoadingStreams,
    String? errorMessage,
    String? successMessage,
  }) {
    return AddonState(
      status: status ?? this.status,
      installedAddons: installedAddons ?? this.installedAddons,
      resolvedStreams: resolvedStreams ?? this.resolvedStreams,
      isLoadingStreams: isLoadingStreams ?? this.isLoadingStreams,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        installedAddons,
        resolvedStreams,
        isLoadingStreams,
        errorMessage,
        successMessage,
      ];
}
