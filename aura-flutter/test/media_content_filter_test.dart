import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/catalog/domain/entities/genre.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/domain/services/media_content_filter.dart';

void main() {
  group('MediaContentFilter Unit Tests', () {
    test('allows legitimate narrative movies and series', () {
      const item1 = MediaItem(
        id: 1,
        title: 'Inception',
        overview: 'A thief who steals corporate secrets...',
        type: MediaType.movie,
        voteAverage: 8.8,
      );

      const item2 = MediaItem(
        id: 2,
        title: 'Breaking Bad',
        overview:
            'A chemistry teacher diagnosed with inoperable lung cancer...',
        type: MediaType.series,
        voteAverage: 9.5,
      );

      expect(MediaContentFilter.isLegitimateNarrative(item1), isTrue);
      expect(MediaContentFilter.isLegitimateNarrative(item2), isTrue);
    });

    test('rejects items with blacklisted stand-up/stage titles', () {
      const comedySpecial = MediaItem(
        id: 101,
        title: 'Dave Chappelle: The Dreamer - Stand-Up Special',
        overview: 'Dave Chappelle returns with a comedy special.',
        type: MediaType.movie,
        voteAverage: 7.2,
      );

      const concertItem = MediaItem(
        id: 102,
        title: 'Taylor Swift: The Eras Tour Live at Wembley',
        overview: 'Concert film of the record-breaking tour.',
        type: MediaType.movie,
        voteAverage: 8.5,
      );

      const stageShow = MediaItem(
        id: 103,
        title: 'Hamilton: The Musical Live',
        overview: 'Live Broadway performance recording.',
        type: MediaType.movie,
        voteAverage: 8.4,
      );

      const roast = MediaItem(
        id: 104,
        title: 'The Roast of Tom Brady',
        overview: 'Celebrity roast event.',
        type: MediaType.movie,
        voteAverage: 7.8,
      );

      expect(MediaContentFilter.isLegitimateNarrative(comedySpecial), isFalse);
      expect(MediaContentFilter.isLegitimateNarrative(concertItem), isFalse);
      expect(MediaContentFilter.isLegitimateNarrative(stageShow), isFalse);
      expect(MediaContentFilter.isLegitimateNarrative(roast), isFalse);
    });

    test('rejects non-narrative TV genres (Talk 10767 & News 10763)', () {
      const talkShow = MediaItem(
        id: 201,
        title: 'The Tonight Show Starring Jimmy Fallon',
        overview: 'Late night talk show.',
        type: MediaType.series,
        genres: [Genre(id: 10767, name: 'Talk')],
      );

      const newsProgram = MediaItem(
        id: 202,
        title: 'BBC News at Ten',
        overview: 'Daily news program.',
        type: MediaType.series,
        genres: [Genre(id: 10763, name: 'News')],
      );

      expect(MediaContentFilter.isLegitimateNarrative(talkShow), isFalse);
      expect(MediaContentFilter.isLegitimateNarrative(newsProgram), isFalse);
    });

    test('sanitize filters out non-narrative media correctly', () {
      const list = [
        MediaItem(
            id: 1,
            title: 'The Dark Knight',
            overview: '',
            type: MediaType.movie),
        MediaItem(
            id: 2,
            title: 'Ricky Gervais: Armageddon Live at Palladium',
            overview: '',
            type: MediaType.movie),
        MediaItem(
            id: 3,
            title: 'Stranger Things',
            overview: '',
            type: MediaType.series),
      ];

      final sanitized = MediaContentFilter.sanitize(list);

      expect(sanitized.length, equals(2));
      expect(sanitized.map((e) => e.title),
          containsAll(['The Dark Knight', 'Stranger Things']));
      expect(sanitized.map((e) => e.title),
          isNot(contains('Ricky Gervais: Armageddon Live at Palladium')));
    });
  });
}
