import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/clips_repository.dart';
import 'clips_event.dart';
import 'clips_state.dart';

class ClipsBloc extends Bloc<ClipsEvent, ClipsState> {
  final ClipsRepository _clipsRepository;

  ClipsBloc({required ClipsRepository clipsRepository})
      : _clipsRepository = clipsRepository,
        super(const ClipsState()) {
    on<LoadClipsEvent>(_onLoadClips);
    on<ChangeActiveClipIndexEvent>(_onChangeActiveClipIndex);
    on<ToggleClipMuteEvent>(_onToggleClipMute);
    on<ToggleClipLikeEvent>(_onToggleClipLike);
  }

  Future<void> _onLoadClips(
    LoadClipsEvent event,
    Emitter<ClipsState> emit,
  ) async {
    emit(state.copyWith(status: ClipsStatus.loading));
    try {
      final clips = await _clipsRepository.getTrendingClips();
      emit(state.copyWith(
        status: ClipsStatus.success,
        clips: clips,
        activeIndex: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ClipsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onChangeActiveClipIndex(
    ChangeActiveClipIndexEvent event,
    Emitter<ClipsState> emit,
  ) {
    if (event.newIndex != state.activeIndex &&
        event.newIndex >= 0 &&
        event.newIndex < state.clips.length) {
      emit(state.copyWith(activeIndex: event.newIndex));
    }
  }

  void _onToggleClipMute(
    ToggleClipMuteEvent event,
    Emitter<ClipsState> emit,
  ) {
    emit(state.copyWith(isMuted: !state.isMuted));
  }

  void _onToggleClipLike(
    ToggleClipLikeEvent event,
    Emitter<ClipsState> emit,
  ) {
    final updated = Set<String>.from(state.likedClipIds);
    if (updated.contains(event.clipId)) {
      updated.remove(event.clipId);
    } else {
      updated.add(event.clipId);
    }
    emit(state.copyWith(likedClipIds: updated));
  }
}
