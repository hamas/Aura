import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'media_interval.dart';
import 'stream_track.dart';

enum PlaybackStatus { idle, buffering, playing, paused, completed, error }

class AuraPlayerState extends Equatable {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final double volume;
  final double rate;
  final String? title;
  final String? subtitle;
  final List<AudioTrackInfo> audioTracks;
  final List<SubtitleTrackInfo> subtitleTracks;
  final AudioTrackInfo? selectedAudioTrack;
  final SubtitleTrackInfo? selectedSubtitleTrack;
  final SubtitleTrackInfo? selectedSecondarySubtitleTrack;
  final double subtitleOffset;
  final String? currentStreamUrl;
  final BoxFit fit;
  final bool enableAuraGlow;
  final bool autoSkipIntros;
  final List<MediaInterval> intervals;
  final MediaInterval? activeInterval;
  final String? errorMessage;

  const AuraPlayerState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.volume = 100.0,
    this.rate = 1.0,
    this.title,
    this.subtitle,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.selectedAudioTrack,
    this.selectedSubtitleTrack,
    this.selectedSecondarySubtitleTrack,
    this.subtitleOffset = 0.0,
    this.currentStreamUrl,
    this.fit = BoxFit.contain,
    this.enableAuraGlow = true,
    this.autoSkipIntros = false,
    this.intervals = const [],
    this.activeInterval,
    this.errorMessage,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isBuffering => status == PlaybackStatus.buffering;

  AuraPlayerState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    Duration? buffer,
    double? volume,
    double? rate,
    String? title,
    String? subtitle,
    List<AudioTrackInfo>? audioTracks,
    List<SubtitleTrackInfo>? subtitleTracks,
    AudioTrackInfo? selectedAudioTrack,
    SubtitleTrackInfo? selectedSubtitleTrack,
    SubtitleTrackInfo? selectedSecondarySubtitleTrack,
    bool clearSecondarySubtitle = false,
    double? subtitleOffset,
    String? currentStreamUrl,
    BoxFit? fit,
    bool? enableAuraGlow,
    bool? autoSkipIntros,
    List<MediaInterval>? intervals,
    MediaInterval? activeInterval,
    bool clearActiveInterval = false,
    String? errorMessage,
  }) {
    return AuraPlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      audioTracks: audioTracks ?? this.audioTracks,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      selectedAudioTrack: selectedAudioTrack ?? this.selectedAudioTrack,
      selectedSubtitleTrack:
          selectedSubtitleTrack ?? this.selectedSubtitleTrack,
      selectedSecondarySubtitleTrack: clearSecondarySubtitle
          ? null
          : (selectedSecondarySubtitleTrack ??
              this.selectedSecondarySubtitleTrack),
      subtitleOffset: subtitleOffset ?? this.subtitleOffset,
      currentStreamUrl: currentStreamUrl ?? this.currentStreamUrl,
      fit: fit ?? this.fit,
      enableAuraGlow: enableAuraGlow ?? this.enableAuraGlow,
      autoSkipIntros: autoSkipIntros ?? this.autoSkipIntros,
      intervals: intervals ?? this.intervals,
      activeInterval:
          clearActiveInterval ? null : (activeInterval ?? this.activeInterval),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        position,
        duration,
        buffer,
        volume,
        rate,
        title,
        subtitle,
        audioTracks,
        subtitleTracks,
        selectedAudioTrack,
        selectedSubtitleTrack,
        selectedSecondarySubtitleTrack,
        subtitleOffset,
        currentStreamUrl,
        fit,
        enableAuraGlow,
        autoSkipIntros,
        intervals,
        activeInterval,
        errorMessage,
      ];
}
