import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/media_kit_player_service.dart';
import '../../domain/entities/player_state.dart';
import 'player_event.dart';

class PlayerBloc extends Bloc<PlayerEvent, AuraPlayerState> {
  final MediaKitPlayerService _playerService;
  StreamSubscription<AuraPlayerState>? _stateSubscription;

  PlayerBloc({required MediaKitPlayerService playerService})
      : _playerService = playerService,
        super(playerService.state) {
    on<PlayerStateUpdatedEvent>((event, emit) => emit(event.state));

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
  }

  Future<void> _onPlayStream(
      PlayStreamEvent event, Emitter<AuraPlayerState> emit) async {
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
