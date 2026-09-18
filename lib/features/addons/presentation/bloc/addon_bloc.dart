import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../domain/entities/addon_manifest.dart';
import '../../domain/repositories/addon_repository.dart';
import 'addon_event.dart';
import 'addon_state.dart';

class AddonBloc extends HydratedBloc<AddonEvent, AddonState> {
  final AddonRepository _addonRepository;

  AddonBloc({required AddonRepository addonRepository})
      : _addonRepository = addonRepository,
        super(const AddonState()) {
    on<LoadAddonsEvent>(_onLoadAddons);
    on<InstallAddonFromUrlEvent>(_onInstallAddonFromUrl);
    on<InstallDirectAddonManifestEvent>(_onInstallDirectAddonManifest);
    on<UninstallAddonEvent>(_onUninstallAddon);
    on<ToggleAddonStatusEvent>(_onToggleAddonStatus);
    on<FetchStreamsForMediaEvent>(_onFetchStreamsForMedia);
  }

  @override
  AddonState? fromJson(Map<String, dynamic> json) {
    try {
      final rawList = json['installedAddons'] as List<dynamic>?;
      if (rawList != null) {
        final addons = rawList.map((e) {
          final map = e as Map;
          return AddonManifest.fromJson(
            Map<String, dynamic>.from(map),
            transportUrl: map['transportUrl']?.toString() ?? '',
          );
        }).toList();
        return AddonState(status: AddonStatus.success, installedAddons: addons);
      }
    } catch (_) {}
    return null;
  }

  @override
  Map<String, dynamic>? toJson(AddonState state) {
    return {
      'installedAddons': state.installedAddons.map((e) => e.toJson()).toList(),
    };
  }

  Future<void> _onLoadAddons(
      LoadAddonsEvent event, Emitter<AddonState> emit) async {
    emit(state.copyWith(status: AddonStatus.loading));
    try {
      final addons = await _addonRepository.getInstalledAddons();
      emit(
          state.copyWith(status: AddonStatus.success, installedAddons: addons));
    } catch (e) {
      emit(state.copyWith(
          status: AddonStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onInstallAddonFromUrl(
      InstallAddonFromUrlEvent event, Emitter<AddonState> emit) async {
    emit(state.copyWith(status: AddonStatus.loading));
    try {
      final manifest = await _addonRepository.fetchManifest(event.manifestUrl);
      await _addonRepository.installAddon(manifest);
      final currentAddons = await _addonRepository.getInstalledAddons();
      final updatedAddons = List<AddonManifest>.from(currentAddons)
        ..removeWhere((addon) => addon.id == manifest.id)
        ..add(manifest);

      emit(state.copyWith(
        status: AddonStatus.success,
        installedAddons: updatedAddons,
        successMessage: 'Successfully installed ${manifest.name}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AddonStatus.failure,
        errorMessage: 'Failed to install add-on: $e',
      ));
    }
  }

  Future<void> _onInstallDirectAddonManifest(
      InstallDirectAddonManifestEvent event, Emitter<AddonState> emit) async {
    emit(state.copyWith(status: AddonStatus.loading));
    try {
      await _addonRepository.installAddon(event.manifest);
      final currentAddons = await _addonRepository.getInstalledAddons();
      final updatedAddons = List<AddonManifest>.from(currentAddons)
        ..removeWhere((addon) => addon.id == event.manifest.id)
        ..add(event.manifest);

      emit(state.copyWith(
        status: AddonStatus.success,
        installedAddons: updatedAddons,
        successMessage: 'Successfully installed ${event.manifest.name}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AddonStatus.failure,
        errorMessage: 'Failed to install add-on: $e',
      ));
    }
  }

  Future<void> _onUninstallAddon(
      UninstallAddonEvent event, Emitter<AddonState> emit) async {
    try {
      await _addonRepository.uninstallAddon(event.addonId);
      final updatedList = await _addonRepository.getInstalledAddons();
      emit(state.copyWith(
        status: AddonStatus.success,
        installedAddons: updatedList,
        successMessage: 'Add-on removed',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AddonStatus.failure,
        errorMessage: 'Failed to remove add-on: $e',
      ));
    }
  }

  Future<void> _onToggleAddonStatus(
      ToggleAddonStatusEvent event, Emitter<AddonState> emit) async {
    try {
      await _addonRepository.toggleAddonStatus(event.addonId, event.isEnabled);
      final updatedList = await _addonRepository.getInstalledAddons();
      emit(state.copyWith(installedAddons: updatedList));
    } catch (e) {
      emit(state.copyWith(
        status: AddonStatus.failure,
        errorMessage: 'Failed to update add-on: $e',
      ));
    }
  }

  Future<void> _onFetchStreamsForMedia(
      FetchStreamsForMediaEvent event, Emitter<AddonState> emit) async {
    emit(state.copyWith(isLoadingStreams: true, resolvedStreams: []));
    try {
      final streams = await _addonRepository.getStreams(
        type: event.type,
        id: event.id,
      );
      emit(state.copyWith(isLoadingStreams: false, resolvedStreams: streams));
    } catch (e) {
      emit(state.copyWith(
        isLoadingStreams: false,
        errorMessage: 'Failed to load streams: $e',
      ));
    }
  }
}
