import 'package:equatable/equatable.dart';
import '../../domain/entities/addon_manifest.dart';

abstract class AddonEvent extends Equatable {
  const AddonEvent();

  @override
  List<Object?> get props => [];
}

class LoadAddonsEvent extends AddonEvent {}

class InstallAddonFromUrlEvent extends AddonEvent {
  final String manifestUrl;
  const InstallAddonFromUrlEvent(this.manifestUrl);

  @override
  List<Object?> get props => [manifestUrl];
}

class UninstallAddonEvent extends AddonEvent {
  final String addonId;
  const UninstallAddonEvent(this.addonId);

  @override
  List<Object?> get props => [addonId];
}

class ToggleAddonStatusEvent extends AddonEvent {
  final String addonId;
  final bool isEnabled;
  const ToggleAddonStatusEvent(this.addonId, this.isEnabled);

  @override
  List<Object?> get props => [addonId, isEnabled];
}

class FetchStreamsForMediaEvent extends AddonEvent {
  final String type;
  final String id;
  const FetchStreamsForMediaEvent({required this.type, required this.id});

  @override
  List<Object?> get props => [type, id];
}

class InstallDirectAddonManifestEvent extends AddonEvent {
  final AddonManifest manifest;
  const InstallDirectAddonManifestEvent(this.manifest);

  @override
  List<Object?> get props => [manifest];
}
