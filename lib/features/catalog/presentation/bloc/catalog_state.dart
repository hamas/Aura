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
    List<MediaItem>? searchResults,
    bool? isSearching,
    MediaItem? selectedMedia,
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
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      selectedMedia: selectedMedia ?? this.selectedMedia,
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
        searchResults,
        isSearching,
        selectedMedia,
        isLoadingDetails,
        currentSeason,
        isLoadingSeason,
        errorMessage,
      ];
}
