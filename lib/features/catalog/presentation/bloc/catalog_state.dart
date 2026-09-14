import 'package:equatable/equatable.dart';
import '../../domain/entities/media_item.dart';

enum CatalogStatus { initial, loading, success, failure }

class CatalogState extends Equatable {
  final CatalogStatus status;
  final List<MediaItem> trending;
  final List<MediaItem> popularMovies;
  final List<MediaItem> popularSeries;
  final List<MediaItem> searchResults;
  final bool isSearching;
  final MediaItem? selectedMedia;
  final bool isLoadingDetails;
  final String? errorMessage;

  const CatalogState({
    this.status = CatalogStatus.initial,
    this.trending = const [],
    this.popularMovies = const [],
    this.popularSeries = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.selectedMedia,
    this.isLoadingDetails = false,
    this.errorMessage,
  });

  CatalogState copyWith({
    CatalogStatus? status,
    List<MediaItem>? trending,
    List<MediaItem>? popularMovies,
    List<MediaItem>? popularSeries,
    List<MediaItem>? searchResults,
    bool? isSearching,
    MediaItem? selectedMedia,
    bool? isLoadingDetails,
    String? errorMessage,
  }) {
    return CatalogState(
      status: status ?? this.status,
      trending: trending ?? this.trending,
      popularMovies: popularMovies ?? this.popularMovies,
      popularSeries: popularSeries ?? this.popularSeries,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      selectedMedia: selectedMedia ?? this.selectedMedia,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        trending,
        popularMovies,
        popularSeries,
        searchResults,
        isSearching,
        selectedMedia,
        isLoadingDetails,
        errorMessage,
      ];
}
