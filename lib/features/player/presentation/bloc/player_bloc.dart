import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/media_kit_player_service.dart';
import '../../domain/entities/media_interval.dart';
import '../../domain/entities/player_state.dart';
import 'player_event.dart';

class PlayerBloc extends Bloc<PlayerEvent, AuraPlayerState> {
  final MediaKitPlayerService _playerService;
  StreamSubscription<AuraPlayerState>? _stateSubscription;
  MediaInterval? _lastAutoSkippedInterval;

  PlayerBloc({required MediaKitPlayerService playerService})
      : _playerService = playerService,
        super(playerService.state) {
    on<PlayerStateUpdatedEvent>(_onPlayerStateUpdated);

    _stateSubscription = _playerService.stateStream.listen((state) {
      add(PlayerStateUpdatedEvent(state));
    });

    on<PlayStreamEvent>(_onPlayStream);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<SeekPositionEvent>(_onSeekPosition);
    on<SetVolumeEvent>(_onSetVolume);
    on<SetPlaybackSpeedEvent>(_onSetPlaybackSpeed);
    on<ChangeAspectRatioEvent>(_onChangeAspectRatio);
    on<SelectAudioTrackEvent>(_onSelectAudioTrack);
    on<SelectSubtitleTrackEvent>(_onSelectSubtitleTrack);
    on<ToggleAuraGlowEvent>(_onToggleAuraGlow);
    on<SetAuraGlowEvent>(_onSetAuraGlow);
    on<SelectSecondarySubtitleTrackEvent>(_onSelectSecondarySubtitleTrack);
    on<SetSubtitleOffsetEvent>(_onSetSubtitleOffset);
    on<NudgeSubtitleOffsetEvent>(_onNudgeSubtitleOffset);
    on<SetAutoSkipIntrosEvent>(_onSetAutoSkipIntros);
    on<SetMediaIntervalsEvent>(_onSetMediaIntervals);
    on<SkipCurrentIntervalEvent>(_onSkipCurrentInterval);
  }

  void _onPlayerStateUpdated(
      PlayerStateUpdatedEvent event, Emitter<AuraPlayerState> emit) {
    final newState = event.state;
    final pos = newState.position;

    // Detect active interval at current playback position
    MediaInterval? currentInterval;
    for (final interval in state.intervals) {
      if (interval.contains(pos)) {
        currentInterval = interval;
        break;
      }
    }

    // Handle Auto-Skip if enabled and interval is intro or recap
    if (state.autoSkipIntros &&
        currentInterval != null &&
        (currentInterval.type == MediaIntervalType.intro ||
            currentInterval.type == MediaIntervalType.recap) &&
        _lastAutoSkippedInterval != currentInterval) {
      _lastAutoSkippedInterval = currentInterval;
      _playerService.seek(currentInterval.skipTarget);
      emit(newState.copyWith(
        activeInterval: currentInterval,
        position: currentInterval.skipTarget,
      ));
      return;
    }

    if (currentInterval == null) {
      _lastAutoSkippedInterval = null;
    }

    emit(newState.copyWith(
      intervals: state.intervals,
      autoSkipIntros: state.autoSkipIntros,
      activeInterval: currentInterval,
      clearActiveInterval: currentInterval == null,
    ));
  }

  void _onSetAutoSkipIntros(
      SetAutoSkipIntrosEvent event, Emitter<AuraPlayerState> emit) {
    emit(state.copyWith(autoSkipIntros: event.enabled));
  }

  void _onSetMediaIntervals(
      SetMediaIntervalsEvent event, Emitter<AuraPlayerState> emit) {
    emit(state.copyWith(intervals: event.intervals));
  }

  Future<void> _onSkipCurrentInterval(
      SkipCurrentIntervalEvent event, Emitter<AuraPlayerState> emit) async {
    final active = state.activeInterval;
    if (active != null) {
      final target = active.skipTarget;
      await _playerService.seek(target);
      emit(state.copyWith(
        position: target,
        clearActiveInterval: true,
      ));
    }
  }

  void _onToggleAuraGlow(
      ToggleAuraGlowEvent event, Emitter<AuraPlayerState> emit) {
    emit(state.copyWith(enableAuraGlow: !state.enableAuraGlow));
  }

  void _onSetAuraGlow(SetAuraGlowEvent event, Emitter<AuraPlayerState> emit) {
    emit(state.copyWith(enableAuraGlow: event.enabled));
  }

  void _onSelectSecondarySubtitleTrack(
      SelectSecondarySubtitleTrackEvent event, Emitter<AuraPlayerState> emit) {
    if (event.track == null) {
      emit(state.copyWith(clearSecondarySubtitle: true));
    } else {
      emit(state.copyWith(selectedSecondarySubtitleTrack: event.track));
    }
  }

  void _onSetSubtitleOffset(
      SetSubtitleOffsetEvent event, Emitter<AuraPlayerState> emit) {
    final clamped = event.offsetSeconds.clamp(-10.0, 10.0);
    emit(state.copyWith(subtitleOffset: clamped));
  }

  void _onNudgeSubtitleOffset(
      NudgeSubtitleOffsetEvent event, Emitter<AuraPlayerState> emit) {
    final newOffset =
        (state.subtitleOffset + event.deltaSeconds).clamp(-10.0, 10.0);
    emit(state.copyWith(subtitleOffset: newOffset));
  }

  Future<void> _onPlayStream(
      PlayStreamEvent event, Emitter<AuraPlayerState> emit) async {
    _lastAutoSkippedInterval = null;
    if (event.intervals != null) {
      emit(state.copyWith(intervals: event.intervals));
    }
    await _playerService.openStream(
      url: event.streamUrl,
      title: event.title,
      subtitle: event.subtitle,
      httpHeaders: event.httpHeaders,
    );
  }

  Future<void> _onTogglePlayPause(
      TogglePlayPauseEvent event, Emitter<AuraPlayerState> emit) async {
    await _playerService.playOrPause();
  }

  Future<void> _onSeekPosition(
      SeekPositionEvent event, Emitter<AuraPlayerState> emit) async {
    await _playerService.seek(event.position);
  }

  Future<void> _onSetVolume(
      SetVolumeEvent event, Emitter<AuraPlayerState> emit) async {
    await _playerService.setVolume(event.volume);
  }

  Future<void> _onSetPlaybackSpeed(
      SetPlaybackSpeedEvent event, Emitter<AuraPlayerState> emit) async {
    await _playerService.setRate(event.speed);
  }

  void _onChangeAspectRatio(
      ChangeAspectRatioEvent event, Emitter<AuraPlayerState> emit) {
    _playerService.setFit(event.fit);
    emit(state.copyWith(fit: event.fit));
  }

  Future<void> _onSelectAudioTrack(
      SelectAudioTrackEvent event, Emitter<AuraPlayerState> emit) async {
    await _playerService.selectAudioTrack(event.track);
  }

  Future<void> _onSelectSubtitleTrack(
      SelectSubtitleTrackEvent event, Emitter<AuraPlayerState> emit) async {
    await _playerService.selectSubtitleTrack(event.track);
  }

  @override
  Future<void> close() {
    _stateSubscription?.cancel();
    return super.close();
  }
}
