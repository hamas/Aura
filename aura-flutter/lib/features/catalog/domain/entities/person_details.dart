import 'package:equatable/equatable.dart';
import '../../../../core/constants/api_constants.dart';
import 'media_item.dart';

class PersonDetails extends Equatable {
  final int id;
  final String name;
  final String biography;
  final String? profilePath;
  final String knownForDepartment;
  final String? birthday;
  final String? placeOfBirth;
  final List<MediaItem> knownFor;

  const PersonDetails({
    required this.id,
    required this.name,
    this.biography = '',
    this.profilePath,
    this.knownForDepartment = 'Acting',
    this.birthday,
    this.placeOfBirth,
    this.knownFor = const [],
  });

  String get fullProfileUrl =>
      profilePath != null ? '${ApiConstants.tmdbPosterW500}$profilePath' : '';

  factory PersonDetails.fromTmdbJson(Map<String, dynamic> json) {
    final credits = json['combined_credits'] as Map<String, dynamic>?;
    final rawCast = credits?['cast'] as List<dynamic>? ?? [];
    final rawCrew = credits?['crew'] as List<dynamic>? ?? [];

    final allRawCredits = <Map<String, dynamic>>[
      ...rawCast.whereType<Map<String, dynamic>>(),
      ...rawCrew.whereType<Map<String, dynamic>>(),
    ];

    final Map<String, MediaItem> itemsMap = {};
    for (final creditJson in allRawCredits) {
      final item = MediaItem.fromTmdbJson(creditJson);
      if (item.posterPath != null && item.posterPath!.isNotEmpty) {
        final key = '${item.type.name}_${item.id}';
        if (!itemsMap.containsKey(key) ||
            item.voteCount > itemsMap[key]!.voteCount) {
          itemsMap[key] = item;
        }
      }
    }

    final knownForList = itemsMap.values.toList();
    knownForList.sort((a, b) {
      final voteComp = b.voteCount.compareTo(a.voteCount);
      if (voteComp != 0) return voteComp;
      return b.voteAverage.compareTo(a.voteAverage);
    });

    return PersonDetails(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      biography: json['biography'] as String? ?? '',
      profilePath: json['profile_path'] != null
          ? '${ApiConstants.tmdbPosterW500}${json['profile_path']}'
          : null,
      knownForDepartment: json['known_for_department'] as String? ?? 'Acting',
      birthday: json['birthday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      knownFor: knownForList,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        biography,
        profilePath,
        knownForDepartment,
        birthday,
        placeOfBirth,
        knownFor,
      ];
}
