import 'package:equatable/equatable.dart';
import '../../domain/entities/clip_item.dart';

enum ClipsStatus { initial, loading, success, failure }

class ClipsState extends Equatable {
  final ClipsStatus status;
  final List<ClipItem> clips;
  final int activeIndex;
  final bool isMuted;
  final Set<String> likedClipIds;
  final String? errorMessage;

  const ClipsState({
    this.status = ClipsStatus.initial,
    this.clips = const [],
    this.activeIndex = 0,
    this.isMuted = false,
    this.likedClipIds = const {},
    this.errorMessage,
  });

  ClipItem? get currentClip =>
      clips.isNotEmpty && activeIndex >= 0 && activeIndex < clips.length
          ? clips[activeIndex]
          : null;

  ClipsState copyWith({
    ClipsStatus? status,
    List<ClipItem>? clips,
    int? activeIndex,
    bool? isMuted,
    Set<String>? likedClipIds,
    String? errorMessage,
  }) {
    return ClipsState(
      status: status ?? this.status,
      clips: clips ?? this.clips,
      activeIndex: activeIndex ?? this.activeIndex,
      isMuted: isMuted ?? this.isMuted,
      likedClipIds: likedClipIds ?? this.likedClipIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        clips,
        activeIndex,
        isMuted,
        likedClipIds,
        errorMessage,
      ];
}
