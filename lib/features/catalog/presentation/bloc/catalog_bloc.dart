import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/catalog_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository _catalogRepository;

  CatalogBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(const CatalogState()) {
    on<LoadDiscoveryFeedsEvent>(_onLoadDiscoveryFeeds);
    on<SearchQueryChangedEvent>(_onSearchQueryChanged);
    on<LoadMediaDetailsEvent>(_onLoadMediaDetails);
  }

  Future<void> _onLoadDiscoveryFeeds(
      LoadDiscoveryFeedsEvent event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    try {
      final results = await Future.wait([
        _catalogRepository.getTrending(),
        _catalogRepository.getPopularMovies(),
        _catalogRepository.getPopularSeries(),
      ]);

      emit(state.copyWith(
        status: CatalogStatus.success,
        trending: results[0],
        popularMovies: results[1],
        popularSeries: results[2],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: 'Failed to load discovery catalog: $e',
      ));
    }
  }

  Future<void> _onSearchQueryChanged(
      SearchQueryChangedEvent event, Emitter<CatalogState> emit) async {
    if (event.query.trim().isEmpty) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }

    emit(state.copyWith(isSearching: true));
    try {
      final results = await _catalogRepository.searchMedia(event.query);
      emit(state.copyWith(searchResults: results, isSearching: false));
    } catch (e) {
      emit(state.copyWith(isSearching: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMediaDetails(
      LoadMediaDetailsEvent event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(isLoadingDetails: true));
    try {
      final details = await _catalogRepository.getMediaDetails(event.id, event.type);
      emit(state.copyWith(selectedMedia: details, isLoadingDetails: false));
    } catch (e) {
      emit(state.copyWith(isLoadingDetails: false, errorMessage: e.toString()));
    }
  }
}
