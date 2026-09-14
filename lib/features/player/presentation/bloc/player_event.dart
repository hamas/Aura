import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/entities/stream_track.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerStateUpdatedEvent extends PlayerEvent {
  final AuraPlayerState state;
  const PlayerStateUpdatedEvent(this.state);

  @override
  List<Object?> get props => [state];
}

class PlayStreamEvent extends PlayerEvent {
  final String streamUrl;
  final String? title;
  final String? subtitle;
  final Map<String, String>? httpHeaders;

  const PlayStreamEvent({
    required this.streamUrl,
    this.title,
    this.subtitle,
    this.httpHeaders,
  });

  @override
  List<Object?> get props => [streamUrl, title, subtitle, httpHeaders];
}

class TogglePlayPauseEvent extends PlayerEvent {}

class SeekPositionEvent extends PlayerEvent {
  final Duration position;
  const SeekPositionEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class SetVolumeEvent extends PlayerEvent {
  final double volume;
  const SetVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class SetPlaybackSpeedEvent extends PlayerEvent {
  final double speed;
  const SetPlaybackSpeedEvent(this.speed);

  @override
  List<Object?> get props => [speed];
}

class ChangeAspectRatioEvent extends PlayerEvent {
  final BoxFit fit;
  const ChangeAspectRatioEvent(this.fit);

  @override
  List<Object?> get props => [fit];
}

class SelectAudioTrackEvent extends PlayerEvent {
  final AudioTrackInfo track;
  const SelectAudioTrackEvent(this.track);

  @override
  List<Object?> get props => [track];
}

class SelectSubtitleTrackEvent extends PlayerEvent {
  final SubtitleTrackInfo? track;
  const SelectSubtitleTrackEvent(this.track);

  @override
  List<Object?> get props => [track];
}
