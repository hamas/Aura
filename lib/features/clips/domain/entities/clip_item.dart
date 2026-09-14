import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:equatable/equatable.dart';

/// Represents an individual full-screen auto-playing trailer / teaser clip.
class ClipItem extends Equatable {
  final String id;
  final int mediaId;
  final String title;
  final String overview;
  final String? videoKey;
  final String? videoUrl;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseYear;
  final MediaType mediaType;
  final List<String> genres;
  final MediaItem mediaItem;

  const ClipItem({
    required this.id,
    required this.mediaId,
    required this.title,
    required this.overview,
    this.videoKey,
    this.videoUrl,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.releaseYear = '',
    required this.mediaType,
    this.genres = const [],
    required this.mediaItem,
  });

  String get formattedRating => voteAverage.toStringAsFixed(1);

  String get fullBackdropUrl => mediaItem.fullBackdropUrl;
  String get fullPosterUrl => mediaItem.fullPosterUrl;

  @override
  List<Object?> get props => [
        id,
        mediaId,
        title,
        overview,
        videoKey,
        videoUrl,
        posterPath,
        backdropPath,
        voteAverage,
        releaseYear,
        mediaType,
        genres,
      ];
}
