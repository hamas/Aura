import 'package:aura/features/catalog/domain/entities/person_details.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersonDetails Entity Tests', () {
    test('fromTmdbJson parses metadata and deduplicates combined credits', () {
      final json = {
        'id': 1234,
        'name': 'Robert Downey Jr.',
        'biography': 'American actor known for Iron Man.',
        'profile_path': '/path.jpg',
        'known_for_department': 'Acting',
        'birthday': '1965-04-04',
        'place_of_birth': 'New York City, New York, USA',
        'combined_credits': {
          'cast': [
            {
              'id': 299536,
              'title': 'Avengers: Infinity War',
              'media_type': 'movie',
              'poster_path': '/poster1.jpg',
              'backdrop_path': '/bg1.jpg',
              'vote_average': 8.3,
              'vote_count': 28000,
              'popularity': 150.0,
            },
            {
              'id': 299536, // Duplicate entry
              'title': 'Avengers: Infinity War',
              'media_type': 'movie',
              'poster_path': '/poster1.jpg',
              'vote_average': 8.3,
              'vote_count': 28000,
            },
          ],
          'crew': [
            {
              'id': 10001,
              'name': 'The Chef Show',
              'media_type': 'tv',
              'poster_path': '/poster2.jpg',
              'vote_average': 7.5,
              'vote_count': 300,
              'popularity': 20.0,
            }
          ]
        }
      };

      final person = PersonDetails.fromTmdbJson(json);

      expect(person.id, 1234);
      expect(person.name, 'Robert Downey Jr.');
      expect(person.biography, 'American actor known for Iron Man.');
      expect(person.profilePath, 'https://image.tmdb.org/t/p/w500/path.jpg');
      expect(person.knownForDepartment, 'Acting');
      expect(person.placeOfBirth, 'New York City, New York, USA');
      expect(person.knownFor.length, 2);

      // Verify sorting: highest vote count first
      expect(person.knownFor.first.id, 299536);
      expect(person.knownFor.first.type, MediaType.movie);
    });
  });
}
