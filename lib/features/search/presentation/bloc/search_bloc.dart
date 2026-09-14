import 'dart:async';
import 'package:aura/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura/features/search/presentation/bloc/search_event.dart';
import 'package:aura/features/search/presentation/bloc/search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

EventTransformer<Event> debounceRestartable<Event>(Duration duration) {
  return (events, mapper) {
    return events.debounceTime(duration).switchMap(mapper);
  };
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final CatalogRepository _catalogRepository;

  SearchBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(const SearchState()) {
    on<SearchQueryChangedEvent>(
      _onQueryChanged,
      transformer: debounceRestartable(const Duration(milliseconds: 250)),
    );
    on<AddRecentSearchEvent>(_onAddRecentSearch);
    on<RemoveRecentSearchEvent>(_onRemoveRecentSearch);
    on<ClearAllRecentSearchesEvent>(_onClearAllRecentSearches);
  }

  Future<void> _onQueryChanged(
    SearchQueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        status: SearchStatus.initial,
        query: '',
        results: const [],
      ));
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading, query: query));

    try {
      final results = await _catalogRepository.searchMedia(query);
      emit(state.copyWith(
        status: SearchStatus.success,
        results: results,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SearchStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onAddRecentSearch(
    AddRecentSearchEvent event,
    Emitter<SearchState> emit,
  ) {
    final query = event.query.trim();
    if (query.isEmpty) return;

    final updated = List<String>.from(state.recentSearches)
      ..remove(query)
      ..insert(0, query);

    emit(state.copyWith(recentSearches: updated.take(10).toList()));
  }

  void _onRemoveRecentSearch(
    RemoveRecentSearchEvent event,
    Emitter<SearchState> emit,
  ) {
    final updated = List<String>.from(state.recentSearches)
      ..remove(event.query);
    emit(state.copyWith(recentSearches: updated));
  }

  void _onClearAllRecentSearches(
    ClearAllRecentSearchesEvent event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(recentSearches: const []));
  }
}
