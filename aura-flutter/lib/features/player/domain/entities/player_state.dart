import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'media_interval.dart';
import 'stream_track.dart';

enum PlaybackStatus { idle, buffering, playing, paused, completed, error, retrying }

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
  final List<String> candidateStreams;
  final int activeCandidateIndex;
  final BoxFit fit;
  final bool enableAuraGlow;
  final bool autoSkipIntros;
  final List<MediaInterval> intervals;
  final MediaInterval? activeInterval;
  final String? errorMessage;
  final bool showNextEpisodeCountdown;
  final int remainingCountdownSeconds;

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
    this.candidateStreams = const [],
    this.activeCandidateIndex = 0,
    this.fit = BoxFit.contain,
    this.enableAuraGlow = true,
    this.autoSkipIntros = false,
    this.intervals = const [],
    this.activeInterval,
    this.errorMessage,
    this.showNextEpisodeCountdown = false,
    this.remainingCountdownSeconds = 0,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isBuffering => status == PlaybackStatus.buffering;
  bool get isRetrying => status == PlaybackStatus.retrying;

  /// Calculated buffer cushion duration (buffer duration - position)
  Duration get bufferCushion {
    if (buffer > position) {
      return buffer - position;
    }
    return Duration.zero;
  }

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
    List<String>? candidateStreams,
    int? activeCandidateIndex,
    BoxFit? fit,
    bool? enableAuraGlow,
    bool? autoSkipIntros,
    List<MediaInterval>? intervals,
    MediaInterval? activeInterval,
    bool clearActiveInterval = false,
    String? errorMessage,
    bool? showNextEpisodeCountdown,
    int? remainingCountdownSeconds,
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
      candidateStreams: candidateStreams ?? this.candidateStreams,
      activeCandidateIndex: activeCandidateIndex ?? this.activeCandidateIndex,
      fit: fit ?? this.fit,
      enableAuraGlow: enableAuraGlow ?? this.enableAuraGlow,
      autoSkipIntros: autoSkipIntros ?? this.autoSkipIntros,
      intervals: intervals ?? this.intervals,
      activeInterval:
          clearActiveInterval ? null : (activeInterval ?? this.activeInterval),
      errorMessage: errorMessage,
      showNextEpisodeCountdown: showNextEpisodeCountdown ?? this.showNextEpisodeCountdown,
      remainingCountdownSeconds: remainingCountdownSeconds ?? this.remainingCountdownSeconds,
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
        candidateStreams,
        activeCandidateIndex,
        fit,
        enableAuraGlow,
        autoSkipIntros,
        intervals,
        activeInterval,
        errorMessage,
        showNextEpisodeCountdown,
        remainingCountdownSeconds,
      ];
}
