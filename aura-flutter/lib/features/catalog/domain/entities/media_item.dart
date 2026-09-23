import 'package:equatable/equatable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/helpers/tmdb_genre_mapper.dart';
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

  String get fullProfileUrl =>
      profilePath != null ? '${ApiConstants.tmdbPosterW500}$profilePath' : '';

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
  final String? logoPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final MediaType type;
  final List<Genre> genres;
  final List<CastMember> cast;
  final List<Season> seasons;
  final int? runtimeMinutes;
  final String? tagline;
  final String? trailerUrl;
  final String? certification;
  final List<String> productionCountries;
  final int? budget;
  final int? revenue;
  final List<String> spokenLanguages;
  final List<String> productionCompanies;

  const MediaItem({
    required this.id,
    this.imdbId,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.logoPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.releaseDate,
    required this.type,
    this.genres = const [],
    this.cast = const [],
    this.seasons = const [],
    this.runtimeMinutes,
    this.tagline,
    this.trailerUrl,
    this.certification,
    this.productionCountries = const [],
    this.budget,
    this.revenue,
    this.spokenLanguages = const [],
    this.productionCompanies = const [],
  });

  String get fullPosterUrl =>
      posterPath != null ? '${ApiConstants.tmdbPosterW500}$posterPath' : '';

  String get fullBackdropUrl => backdropPath != null
      ? '${ApiConstants.tmdbBackdropW1280}$backdropPath'
      : '';

  String? get logoUrl =>
      logoPath != null ? 'https://image.tmdb.org/t/p/w500$logoPath' : null;

  List<int> get genreIds => genres.map((g) => g.id).toList();

  String get releaseYear {
    if (releaseDate != null && releaseDate!.length >= 4) {
      return releaseDate!.substring(0, 4);
    }
    return '';
  }

  String get formattedRating => voteAverage.toStringAsFixed(1);

  /// Returns true if the media item has a release date that is today or in the past.
  bool get isReleased {
    if (releaseDate == null || releaseDate!.trim().isEmpty) return true;
    try {
      final parsed = DateTime.parse(releaseDate!.trim());
      final now = DateTime.now();
      // Compare dates ignoring time
      final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
      return !parsed.isAfter(today);
    } catch (_) {
      return true;
    }
  }

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
    String? logoPath,
    double? voteAverage,
    int? voteCount,
    String? releaseDate,
    MediaType? type,
    List<Genre>? genres,
    List<CastMember>? cast,
    List<Season>? seasons,
    int? runtimeMinutes,
    String? tagline,
    String? trailerUrl,
    String? certification,
    List<String>? productionCountries,
    int? budget,
    int? revenue,
    List<String>? spokenLanguages,
    List<String>? productionCompanies,
  }) {
    return MediaItem(
      id: id ?? this.id,
      imdbId: imdbId ?? this.imdbId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      logoPath: logoPath ?? this.logoPath,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      releaseDate: releaseDate ?? this.releaseDate,
      type: type ?? this.type,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      seasons: seasons ?? this.seasons,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      tagline: tagline ?? this.tagline,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      certification: certification ?? this.certification,
      productionCountries: productionCountries ?? this.productionCountries,
      budget: budget ?? this.budget,
      revenue: revenue ?? this.revenue,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
      productionCompanies: productionCompanies ?? this.productionCompanies,
    );
  }

  factory MediaItem.fromTmdbJson(Map<String, dynamic> json,
      {MediaType? explicitType}) {
    final bool isMovie;
    if (explicitType != null) {
      isMovie = explicitType == MediaType.movie;
    } else if (json['media_type'] != null) {
      isMovie = json['media_type'] == 'movie';
    } else {
      isMovie = json.containsKey('title') || json.containsKey('release_date');
    }

    final rawGenres = json['genres'] as List<dynamic>?;
    final rawGenreIds = (json['genre_ids'] as List<dynamic>?)
        ?.map((e) => (e as num).toInt())
        .toList();

    List<Genre> genresList = [];
    if (rawGenres != null && rawGenres.isNotEmpty) {
      genresList = rawGenres
          .whereType<Map<String, dynamic>>()
          .map((g) => Genre.fromJson(g))
          .toList();
    } else if (rawGenreIds != null && rawGenreIds.isNotEmpty) {
      genresList = rawGenreIds.map((id) {
        final names = TmdbGenreMapper.getGenreNames([id]);
        final name = names.isNotEmpty ? names.first : 'Genre';
        return Genre(id: id, name: name);
      }).toList();
    }

    final rawCredits = json['credits'];
    List<CastMember> castList = [];
    if (rawCredits is Map<String, dynamic> && rawCredits['cast'] is List) {
      castList = (rawCredits['cast'] as List<dynamic>)
          .take(15)
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

    // Logo resolution from appended images or direct key
    String? logo;
    if (json['logo_path'] != null) {
      logo = json['logo_path'] as String;
    } else if (json['images'] is Map && json['images']['logos'] is List) {
      final logos = (json['images']['logos'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
      if (logos.isNotEmpty) {
        final enLogo = logos.firstWhere(
          (l) => l['iso_639_1'] == 'en',
          orElse: () => logos.first,
        );
        logo = enLogo['file_path'] as String?;
      }
    }

    final relDate = (json['release_date'] ?? json['first_air_date']) as String?;

    // Safe extraction of production countries
    final rawCountries = json['production_countries'] as List<dynamic>? ?? [];
    final countries = rawCountries
        .whereType<Map<String, dynamic>>()
        .map((c) => (c['name'] ?? c['iso_3166_1'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();

    // Safe extraction of spoken languages
    final rawLanguages = json['spoken_languages'] as List<dynamic>? ?? [];
    final languages = rawLanguages
        .whereType<Map<String, dynamic>>()
        .map((l) => (l['english_name'] ?? l['name'] ?? l['iso_639_1'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();

    // Safe extraction of production companies
    final rawCompanies = json['production_companies'] as List<dynamic>? ?? [];
    final companies = rawCompanies
        .whereType<Map<String, dynamic>>()
        .map((c) => (c['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();

    // Runtime extraction (handle movie runtime array or tv episode_run_time)
    int? runtime;
    if (json['runtime'] is num) {
      runtime = (json['runtime'] as num).toInt();
    } else if (json['episode_run_time'] is List && (json['episode_run_time'] as List).isNotEmpty) {
      runtime = ((json['episode_run_time'] as List).first as num?)?.toInt();
    }

    // Certification rating extraction if available in content_ratings / release_dates
    String? cert;
    if (json['certification'] is String) {
      cert = json['certification'] as String;
    }

    return MediaItem(
      id: json['id'] as int? ?? 0,
      imdbId: imdb,
      title: ((isMovie ? json['title'] : json['name']) ??
          json['title'] ??
          json['name'] ??
          'Untitled') as String,
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      logoPath: logo,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: relDate,
      type: isMovie ? MediaType.movie : MediaType.series,
      genres: genresList,
      cast: castList,
      seasons: seasonsList,
      runtimeMinutes: runtime,
      tagline: json['tagline'] as String?,
      trailerUrl: _parseTrailerUrl(json),
      certification: cert,
      productionCountries: countries,
      budget: (json['budget'] as num?)?.toInt(),
      revenue: (json['revenue'] as num?)?.toInt(),
      spokenLanguages: languages,
      productionCompanies: companies,
    );
  }

  static String? _parseTrailerUrl(Map<String, dynamic> json) {
    if (json['videos'] is Map && json['videos']['results'] is List) {
      final videos = (json['videos']['results'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
      return extractTrailerUrlFromVideos(videos);
    }
    return null;
  }

  static String? extractTrailerUrlFromVideos(List<Map<String, dynamic>> videos) {
    if (videos.isEmpty) return null;

    final ytVideos = videos
        .where((v) =>
            v['site'] == 'YouTube' &&
            v['key'] != null &&
            (v['key'] as String).trim().isNotEmpty)
        .toList();
    if (ytVideos.isEmpty) return null;

    // 1. Official Trailer
    final officialTrailer = ytVideos.firstWhere(
      (v) =>
          (v['official'] == true || v['official'] == 1) &&
          v['type'] == 'Trailer',
      orElse: () => <String, dynamic>{},
    );
    if (officialTrailer['key'] != null) {
      return 'https://www.youtube.com/watch?v=${officialTrailer['key']}';
    }

    // 2. Any Trailer
    final anyTrailer = ytVideos.firstWhere(
      (v) => v['type'] == 'Trailer',
      orElse: () => <String, dynamic>{},
    );
    if (anyTrailer['key'] != null) {
      return 'https://www.youtube.com/watch?v=${anyTrailer['key']}';
    }

    // 3. Teaser, Clip, or Featurette
    final teaserOrClip = ytVideos.firstWhere(
      (v) =>
          v['type'] == 'Teaser' ||
          v['type'] == 'Clip' ||
          v['type'] == 'Featurette',
      orElse: () => <String, dynamic>{},
    );
    if (teaserOrClip['key'] != null) {
      return 'https://www.youtube.com/watch?v=${teaserOrClip['key']}';
    }

    // 4. Any YouTube video entry fallback
    final fallback = ytVideos.first;
    return 'https://www.youtube.com/watch?v=${fallback['key']}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imdb_id': imdbId,
        'title': title,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'logo_path': logoPath,
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
        logoPath,
        voteAverage,
        releaseDate,
        type,
        genres,
      ];
}
