import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:equatable/equatable.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final List<MediaItem> results;
  final List<String> recentSearches;
  final List<String> trendingTags;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.recentSearches = const [
      'Dune',
      'Cyberpunk',
      'Interstellar',
      'Oppenheimer',
    ],
    this.trendingTags = const [
      'Sci-Fi',
      'A24',
      'Oscar Winners',
      'Cyberpunk',
      'Anime',
      'Marvel',
      'Noir',
      'Mind Bending',
    ],
    this.errorMessage,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<MediaItem>? results,
    List<String>? recentSearches,
    List<String>? trendingTags,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      trendingTags: trendingTags ?? this.trendingTags,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        query,
        results,
        recentSearches,
        trendingTags,
        errorMessage,
      ];
}
