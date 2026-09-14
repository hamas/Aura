import 'package:equatable/equatable.dart';

abstract class ClipsEvent extends Equatable {
  const ClipsEvent();

  @override
  List<Object?> get props => [];
}

class LoadClipsEvent extends ClipsEvent {}

class ChangeActiveClipIndexEvent extends ClipsEvent {
  final int newIndex;
  const ChangeActiveClipIndexEvent(this.newIndex);

  @override
  List<Object?> get props => [newIndex];
}

class ToggleClipMuteEvent extends ClipsEvent {}

class ToggleClipLikeEvent extends ClipsEvent {
  final String clipId;
  const ToggleClipLikeEvent(this.clipId);

  @override
  List<Object?> get props => [clipId];
}
