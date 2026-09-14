import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/addon_repository.dart';
import 'addon_event.dart';
import 'addon_state.dart';

class AddonBloc extends Bloc<AddonEvent, AddonState> {
  final AddonRepository _addonRepository;

  AddonBloc({required AddonRepository addonRepository})
      : _addonRepository = addonRepository,
        super(const AddonState()) {
    on<LoadAddonsEvent>(_onLoadAddons);
    on<InstallAddonFromUrlEvent>(_onInstallAddonFromUrl);
    on<UninstallAddonEvent>(_onUninstallAddon);
    on<ToggleAddonStatusEvent>(_onToggleAddonStatus);
    on<FetchStreamsForMediaEvent>(_onFetchStreamsForMedia);
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
      final updatedList = await _addonRepository.getInstalledAddons();
      emit(state.copyWith(
        status: AddonStatus.success,
        installedAddons: updatedList,
        successMessage: 'Successfully installed ${manifest.name}',
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
