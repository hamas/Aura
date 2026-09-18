import 'package:flutter/widgets.dart';
import '../../domain/entities/media_interval.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/entities/stream_track.dart';

abstract class PlayerEvent {
  const PlayerEvent();
}

class PlayerStateUpdatedEvent extends PlayerEvent {
  final AuraPlayerState state;
  const PlayerStateUpdatedEvent(this.state);
}

class PlayStreamEvent extends PlayerEvent {
  final String streamUrl;
  final String? title;
  final String? subtitle;
  final Map<String, String>? httpHeaders;
  final List<MediaInterval>? intervals;
  final List<String>? candidateStreams;
  final int candidateIndex;

  const PlayStreamEvent({
    required this.streamUrl,
    this.title,
    this.subtitle,
    this.httpHeaders,
    this.intervals,
    this.candidateStreams,
    this.candidateIndex = 0,
  });
}

class TogglePlayPauseEvent extends PlayerEvent {
  const TogglePlayPauseEvent();
}

class SeekPositionEvent extends PlayerEvent {
  final Duration position;
  const SeekPositionEvent(this.position);
}

class SetVolumeEvent extends PlayerEvent {
  final double volume;
  const SetVolumeEvent(this.volume);
}

class SetPlaybackSpeedEvent extends PlayerEvent {
  final double speed;
  const SetPlaybackSpeedEvent(this.speed);
}

class ChangeAspectRatioEvent extends PlayerEvent {
  final BoxFit fit;
  const ChangeAspectRatioEvent(this.fit);
}

class SelectAudioTrackEvent extends PlayerEvent {
  final AudioTrackInfo track;
  const SelectAudioTrackEvent(this.track);
}

class SelectSubtitleTrackEvent extends PlayerEvent {
  final SubtitleTrackInfo? track;
  const SelectSubtitleTrackEvent(this.track);
}

class SelectSecondarySubtitleTrackEvent extends PlayerEvent {
  final SubtitleTrackInfo? track;
  const SelectSecondarySubtitleTrackEvent(this.track);
}

class SetSubtitleOffsetEvent extends PlayerEvent {
  final double offsetSeconds;
  const SetSubtitleOffsetEvent(this.offsetSeconds);
}

class NudgeSubtitleOffsetEvent extends PlayerEvent {
  final double deltaSeconds;
  const NudgeSubtitleOffsetEvent(this.deltaSeconds);
}

class ToggleAuraGlowEvent extends PlayerEvent {
  const ToggleAuraGlowEvent();
}

class SetAuraGlowEvent extends PlayerEvent {
  final bool enabled;
  const SetAuraGlowEvent(this.enabled);
}

class SetAutoSkipIntrosEvent extends PlayerEvent {
  final bool enabled;
  const SetAutoSkipIntrosEvent(this.enabled);
}

class SetMediaIntervalsEvent extends PlayerEvent {
  final List<MediaInterval> intervals;
  const SetMediaIntervalsEvent(this.intervals);
}

class SkipCurrentIntervalEvent extends PlayerEvent {
  const SkipCurrentIntervalEvent();
}
