import 'package:equatable/equatable.dart';
import '../../../../core/constants/api_constants.dart';
import 'genre.dart';
import 'season_episode.dart';

enum MediaType { movie, series }

class CastMember extends Equatable {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  const CastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      character: json['character'] as String? ?? '',
      profilePath: json['profile_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'character': character,
        'profile_path': profilePath,
      };

  @override
  List<Object?> get props => [id, name, character, profilePath];
}

class MediaItem extends Equatable {
  final int id;
  final String? imdbId;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;
  final MediaType type;
  final List<Genre> genres;
  final List<CastMember> cast;
  final List<Season> seasons;
  final int? runtimeMinutes;
  final String? tagline;

  const MediaItem({
    required this.id,
    this.imdbId,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.releaseDate,
    required this.type,
    this.genres = const [],
    this.cast = const [],
    this.seasons = const [],
    this.runtimeMinutes,
    this.tagline,
  });

  String get fullPosterUrl =>
      posterPath != null ? '${ApiConstants.tmdbPosterW500}$posterPath' : '';

  String get fullBackdropUrl => backdropPath != null
      ? '${ApiConstants.tmdbBackdropW1280}$backdropPath'
      : '';

  String get releaseYear {
    if (releaseDate != null && releaseDate!.length >= 4) {
      return releaseDate!.substring(0, 4);
    }
    return '';
  }

  String get formattedRating => voteAverage.toStringAsFixed(1);

  /// Generates the Stremio standardized ID for add-on querying
  String getStremioId({int? season, int? episode}) {
    final effectiveId = imdbId ?? 'tmdb:$id';
    if (type == MediaType.series && season != null && episode != null) {
      return '$effectiveId:$season:$episode';
    }
    return effectiveId;
  }

  MediaItem copyWith({
    int? id,
    String? imdbId,
    String? title,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? voteAverage,
    String? releaseDate,
    MediaType? type,
    List<Genre>? genres,
    List<CastMember>? cast,
    List<Season>? seasons,
    int? runtimeMinutes,
    String? tagline,
  }) {
    return MediaItem(
      id: id ?? this.id,
      imdbId: imdbId ?? this.imdbId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      type: type ?? this.type,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      seasons: seasons ?? this.seasons,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      tagline: tagline ?? this.tagline,
    );
  }

  factory MediaItem.fromTmdbJson(Map<String, dynamic> json,
      {MediaType? explicitType}) {
    final isMovie = (explicitType != null && explicitType == MediaType.movie) ||
        json.containsKey('title') ||
        json['media_type'] == 'movie';

    final rawGenres = json['genres'] as List<dynamic>? ?? [];
    final genresList = rawGenres
        .whereType<Map<String, dynamic>>()
        .map((g) => Genre.fromJson(g))
        .toList();

    final rawCredits = json['credits'];
    List<CastMember> castList = [];
    if (rawCredits is Map<String, dynamic> && rawCredits['cast'] is List) {
      castList = (rawCredits['cast'] as List<dynamic>)
          .take(10)
          .whereType<Map<String, dynamic>>()
          .map((c) => CastMember.fromJson(c))
          .toList();
    }

    final rawSeasons = json['seasons'] as List<dynamic>? ?? [];
    final seasonsList = rawSeasons
        .whereType<Map<String, dynamic>>()
        .where((s) => (s['season_number'] as int? ?? 0) > 0)
        .map((s) => Season.fromJson(s))
        .toList();

    // IMDb ID can come from external_ids or direct key
    String? imdb;
    if (json['imdb_id'] != null) {
      imdb = json['imdb_id'] as String;
    } else if (json['external_ids'] is Map) {
      imdb = json['external_ids']['imdb_id'] as String?;
    }

    return MediaItem(
      id: json['id'] as int? ?? 0,
      imdbId: imdb,
      title: (isMovie ? json['title'] : json['name']) as String? ?? 'Untitled',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate:
          (isMovie ? json['release_date'] : json['first_air_date']) as String?,
      type: isMovie ? MediaType.movie : MediaType.series,
      genres: genresList,
      cast: castList,
      seasons: seasonsList,
      runtimeMinutes: json['runtime'] as int?,
      tagline: json['tagline'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imdb_id': imdbId,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'vote_average': voteAverage,
        'release_date': releaseDate,
        'type': type.name,
        'genres': genres.map((g) => g.toJson()).toList(),
        'cast': cast.map((c) => c.toJson()).toList(),
        'seasons': seasons.map((s) => s.toJson()).toList(),
        'runtime': runtimeMinutes,
        'tagline': tagline,
      };

  @override
  List<Object?> get props => [
        id,
        imdbId,
        title,
        overview,
        posterPath,
        backdropPath,
        voteAverage,
        releaseDate,
        type,
        genres,
      ];
}
