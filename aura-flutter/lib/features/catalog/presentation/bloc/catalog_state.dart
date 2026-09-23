import 'package:equatable/equatable.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/season_episode.dart';

enum CatalogStatus { initial, loading, success, failure }

class CatalogState extends Equatable {
  final CatalogStatus status;
  final List<MediaItem> trending;
  final List<MediaItem> trendingMovies;
  final List<MediaItem> trendingSeries;
  final List<MediaItem> popularMovies;
  final List<MediaItem> popularSeries;
  final List<MediaItem> latestMovies;
  final List<MediaItem> latestSeries;
  final List<MediaItem> internationalHits;
  final List<MediaItem> gridItems;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final List<MediaItem> searchResults;
  final bool isSearching;
  final MediaItem? selectedMedia;
  final bool isLoadingDetails;
  final Season? currentSeason;
  final bool isLoadingSeason;
  final String? errorMessage;

  const CatalogState({
    this.status = CatalogStatus.initial,
    this.trending = const [],
    this.trendingMovies = const [],
    this.trendingSeries = const [],
    this.popularMovies = const [],
    this.popularSeries = const [],
    this.latestMovies = const [],
    this.latestSeries = const [],
    this.internationalHits = const [],
    this.gridItems = const [],
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.searchResults = const [],
    this.isSearching = false,
    this.selectedMedia,
    this.isLoadingDetails = false,
    this.currentSeason,
    this.isLoadingSeason = false,
    this.errorMessage,
  });

  CatalogState copyWith({
    CatalogStatus? status,
    List<MediaItem>? trending,
    List<MediaItem>? trendingMovies,
    List<MediaItem>? trendingSeries,
    List<MediaItem>? popularMovies,
    List<MediaItem>? popularSeries,
    List<MediaItem>? latestMovies,
    List<MediaItem>? latestSeries,
    List<MediaItem>? internationalHits,
    List<MediaItem>? gridItems,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasReachedMax,
    List<MediaItem>? searchResults,
    bool? isSearching,
    MediaItem? selectedMedia,
    bool clearSelectedMedia = false,
    bool? isLoadingDetails,
    Season? currentSeason,
    bool? isLoadingSeason,
    String? errorMessage,
  }) {
    return CatalogState(
      status: status ?? this.status,
      trending: trending ?? this.trending,
      trendingMovies: trendingMovies ?? this.trendingMovies,
      trendingSeries: trendingSeries ?? this.trendingSeries,
      popularMovies: popularMovies ?? this.popularMovies,
      popularSeries: popularSeries ?? this.popularSeries,
      latestMovies: latestMovies ?? this.latestMovies,
      latestSeries: latestSeries ?? this.latestSeries,
      internationalHits: internationalHits ?? this.internationalHits,
      gridItems: gridItems ?? this.gridItems,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      selectedMedia:
          clearSelectedMedia ? null : (selectedMedia ?? this.selectedMedia),
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      currentSeason: currentSeason ?? this.currentSeason,
      isLoadingSeason: isLoadingSeason ?? this.isLoadingSeason,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        trending,
        trendingMovies,
        trendingSeries,
        popularMovies,
        popularSeries,
        latestMovies,
        latestSeries,
        internationalHits,
        gridItems,
        currentPage,
        isLoadingMore,
        hasReachedMax,
        searchResults,
        isSearching,
        selectedMedia,
        isLoadingDetails,
        currentSeason,
        isLoadingSeason,
        errorMessage,
      ];
}
