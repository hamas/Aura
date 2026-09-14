import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
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
  final String? currentStreamUrl;
  final BoxFit fit;
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
    this.currentStreamUrl,
    this.fit = BoxFit.contain,
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
    String? currentStreamUrl,
    BoxFit? fit,
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
      selectedSubtitleTrack: selectedSubtitleTrack ?? this.selectedSubtitleTrack,
      currentStreamUrl: currentStreamUrl ?? this.currentStreamUrl,
      fit: fit ?? this.fit,
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
        currentStreamUrl,
        fit,
        errorMessage,
      ];
}
