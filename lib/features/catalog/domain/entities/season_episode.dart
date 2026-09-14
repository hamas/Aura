import 'package:equatable/equatable.dart';

class Episode extends Equatable {
  final int id;
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final String overview;
  final String? stillPath;
  final double voteAverage;
  final String? airDate;

  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    this.stillPath,
    this.voteAverage = 0.0,
    this.airDate,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 1,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? 'Episode',
      overview: json['overview'] as String? ?? '',
      stillPath: json['still_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      airDate: json['air_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'episode_number': episodeNumber,
        'season_number': seasonNumber,
        'name': name,
        'overview': overview,
        'still_path': stillPath,
        'vote_average': voteAverage,
        'air_date': airDate,
      };

  @override
  List<Object?> get props => [id, episodeNumber, seasonNumber, name, stillPath, voteAverage];
}

class Season extends Equatable {
  final int id;
  final int seasonNumber;
  final String name;
  final String overview;
  final String? posterPath;
  final int episodeCount;
  final List<Episode> episodes;

  const Season({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    this.posterPath,
    this.episodeCount = 0,
    this.episodes = const [],
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    final rawEpisodes = json['episodes'] as List<dynamic>? ?? [];
    return Season(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 1,
      name: json['name'] as String? ?? 'Season',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      episodeCount: json['episode_count'] as int? ?? rawEpisodes.length,
      episodes: rawEpisodes
          .whereType<Map<String, dynamic>>()
          .map((e) => Episode.fromJson(e))
          .toList(),
    );
  }

  Season copyWith({
    int? id,
    int? seasonNumber,
    String? name,
    String? overview,
    String? posterPath,
    int? episodeCount,
    List<Episode>? episodes,
  }) {
    return Season(
      id: id ?? this.id,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      episodeCount: episodeCount ?? this.episodeCount,
      episodes: episodes ?? this.episodes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'season_number': seasonNumber,
        'name': name,
        'overview': overview,
        'poster_path': posterPath,
        'episode_count': episodeCount,
        'episodes': episodes.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, seasonNumber, name, posterPath, episodeCount, episodes];
}
