import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/library_item.dart';
import '../../domain/repositories/library_repository.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryRepository _libraryRepository;

  LibraryBloc({required LibraryRepository libraryRepository})
      : _libraryRepository = libraryRepository,
        super(const LibraryState()) {
    on<LoadLibraryEvent>(_onLoadLibrary);
    on<ToggleWatchlistEvent>(_onToggleWatchlist);
    on<ToggleWishlistEvent>(_onToggleWishlist);
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<RemoveLibraryItemEvent>(_onRemoveLibraryItem);
  }

  Future<void> _onLoadLibrary(
      LoadLibraryEvent event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final results = await Future.wait([
        _libraryRepository.getLibraryItems(category: LibraryCategory.watchlist),
        _libraryRepository.getLibraryItems(category: LibraryCategory.wishlist),
        _libraryRepository.getLibraryItems(
            category: LibraryCategory.continueWatching),
        _libraryRepository.getLibraryItems(category: LibraryCategory.history),
      ]);

      emit(state.copyWith(
        status: LibraryStatus.success,
        watchlist: results[0],
        wishlist: results[1],
        continueWatching: results[2],
        history: results[3],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LibraryStatus.failure,
        errorMessage: 'Failed to load library: $e',
      ));
    }
  }

  Future<void> _onToggleWatchlist(
      ToggleWatchlistEvent event, Emitter<LibraryState> emit) async {
    try {
      if (state.isInWatchlist(event.item.id)) {
        await _libraryRepository.removeItem(event.item.id);
      } else {
        await _libraryRepository.saveLibraryItem(event.item);
      }
      add(LoadLibraryEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update watchlist: $e'));
    }
  }

  Future<void> _onToggleWishlist(
      ToggleWishlistEvent event, Emitter<LibraryState> emit) async {
    try {
      if (state.isInWishlist(event.item.id)) {
        await _libraryRepository.removeItem(event.item.id);
      } else {
        await _libraryRepository.saveLibraryItem(
          LibraryItem(
            id: event.item.id,
            title: event.item.title,
            posterPath: event.item.posterPath,
            backdropPath: event.item.backdropPath,
            type: event.item.type,
            category: LibraryCategory.wishlist,
            updatedAt: DateTime.now(),
          ),
        );
      }
      add(LoadLibraryEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update wishlist: $e'));
    }
  }

  Future<void> _onUpdateProgress(
      UpdateProgressEvent event, Emitter<LibraryState> emit) async {
    try {
      await _libraryRepository.updateWatchProgress(
        mediaId: event.mediaId,
        title: event.title,
        posterPath: event.posterPath,
        backdropPath: event.backdropPath,
        type: event.type,
        positionSeconds: event.positionSeconds,
        durationSeconds: event.durationSeconds,
        seasonNumber: event.seasonNumber,
        episodeNumber: event.episodeNumber,
      );
      add(LoadLibraryEvent());
    } catch (e) {
      // Suppress background sync errors to not disturb playback
    }
  }

  Future<void> _onRemoveLibraryItem(
      RemoveLibraryItemEvent event, Emitter<LibraryState> emit) async {
    try {
      await _libraryRepository.removeItem(event.mediaId);
      add(LoadLibraryEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to remove item: $e'));
    }
  }
}
