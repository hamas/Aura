import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/repositories/catalog_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository _catalogRepository;

  CatalogBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(const CatalogState()) {
    on<LoadDiscoveryFeedsEvent>(_onLoadDiscoveryFeeds);
    on<LoadMoreCatalogEvent>(_onLoadMoreCatalog);
    on<SearchQueryChangedEvent>(_onSearchQueryChanged);
    on<LoadMediaDetailsEvent>(_onLoadMediaDetails);
    on<LoadSeasonDetailsEvent>(_onLoadSeasonDetails);
  }

  Future<void> _onLoadDiscoveryFeeds(
      LoadDiscoveryFeedsEvent event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    try {
      final results = await Future.wait([
        _catalogRepository.getTrending(),
        _catalogRepository.getTrendingMovies(),
        _catalogRepository.getTrendingSeries(),
        _catalogRepository.getPopularMovies(),
        _catalogRepository.getPopularSeries(),
        _catalogRepository.getNowPlayingMovies(),
        _catalogRepository.getOnTheAirSeries(),
        _catalogRepository.getInternationalHits(),
      ]);

      final initialGrid = <MediaItem>[...results[3], ...results[4]];
      final uniqueGrid = _deduplicate(initialGrid);

      emit(state.copyWith(
        status: CatalogStatus.success,
        trending: results[0],
        trendingMovies: results[1],
        trendingSeries: results[2],
        popularMovies: results[3],
        popularSeries: results[4],
        latestMovies: results[5],
        latestSeries: results[6],
        internationalHits: results[7],
        gridItems: uniqueGrid,
        currentPage: 1,
        hasReachedMax: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: 'Failed to load discovery catalog: $e',
      ));
    }
  }

  Future<void> _onLoadMoreCatalog(
      LoadMoreCatalogEvent event, Emitter<CatalogState> emit) async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final results = await Future.wait([
        _catalogRepository.getPopularMovies(page: nextPage),
        _catalogRepository.getPopularSeries(page: nextPage),
      ]);

      final newItems = <MediaItem>[...results[0], ...results[1]];
      if (newItems.isEmpty) {
        emit(state.copyWith(isLoadingMore: false, hasReachedMax: true));
        return;
      }

      final updatedGrid = _deduplicate([...state.gridItems, ...newItems]);
      emit(state.copyWith(
        gridItems: updatedGrid,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  List<MediaItem> _deduplicate(List<MediaItem> items) {
    final seen = <String>{};
    final unique = <MediaItem>[];
    for (final item in items) {
      final key = '${item.type.name}_${item.id}';
      if (seen.add(key)) {
        unique.add(item);
      }
    }
    return unique;
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
    emit(state.copyWith(
      isLoadingDetails: true,
      clearSelectedMedia: true,
      currentSeason: null,
    ));
    try {
      final details =
          await _catalogRepository.getMediaDetails(event.id, event.type);
      emit(state.copyWith(selectedMedia: details, isLoadingDetails: false));

      if (event.type == MediaType.series && details.seasons.isNotEmpty) {
        final initialSeasonNumber = details.seasons.first.seasonNumber;
        add(LoadSeasonDetailsEvent(
          seriesId: event.id,
          seasonNumber: initialSeasonNumber,
        ));
      }
    } catch (e) {
      emit(state.copyWith(isLoadingDetails: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadSeasonDetails(
      LoadSeasonDetailsEvent event, Emitter<CatalogState> emit) async {
    emit(state.copyWith(isLoadingSeason: true));
    try {
      final season = await _catalogRepository.getSeasonDetails(
        event.seriesId,
        event.seasonNumber,
      );
      emit(state.copyWith(currentSeason: season, isLoadingSeason: false));
    } catch (e) {
      emit(state.copyWith(isLoadingSeason: false, errorMessage: e.toString()));
    }
  }
}
