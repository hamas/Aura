import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura/features/clips/domain/entities/clip_item.dart';
import 'package:aura/features/clips/domain/repositories/clips_repository.dart';

class ClipsRepositoryImpl implements ClipsRepository {
  final CatalogRepository _catalogRepository;

  ClipsRepositoryImpl({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository;

  @override
  Future<List<ClipItem>> getTrendingClips() async {
    try {
      final trending = await _catalogRepository.getTrending();
      final clips = <ClipItem>[];

      for (final media in trending) {
        if (media.backdropPath == null && media.posterPath == null) continue;

        String? videoKey;
        try {
          final videos =
              await _catalogRepository.getVideos(media.id, media.type);
          final trailer = videos.firstWhere(
            (Map<String, dynamic> v) =>
                v['site'] == 'YouTube' &&
                (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
            orElse: () =>
                videos.isNotEmpty ? videos.first : <String, dynamic>{},
          );
          if (trailer.containsKey('key')) {
            videoKey = trailer['key'] as String?;
          }
        } catch (_) {
          // Continue if video query encounters an isolated network hiccup
        }

        clips.add(
          ClipItem(
            id: 'clip_${media.type.name}_${media.id}',
            mediaId: media.id,
            title: media.title,
            overview: media.overview,
            videoKey: videoKey,
            posterPath: media.posterPath,
            backdropPath: media.backdropPath,
            voteAverage: media.voteAverage,
            releaseYear: media.releaseYear,
            mediaType: media.type,
            genres: media.genres.map((g) => g.name).toList(),
            mediaItem: media,
          ),
        );
      }

      if (clips.isNotEmpty) {
        return clips;
      }
      return _getFallbackClips();
    } catch (_) {
      return _getFallbackClips();
    }
  }

  List<ClipItem> _getFallbackClips() {
    return [
      const ClipItem(
        id: 'clip_movie_693134',
        mediaId: 693134,
        title: 'Dune: Part Two',
        overview:
            'Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a path of revenge against the conspirators who destroyed his family.',
        videoKey: 'Way9Dexny3w',
        posterPath: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
        backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520b4.jpg',
        voteAverage: 8.3,
        releaseYear: '2024',
        mediaType: MediaType.movie,
        genres: ['Sci-Fi', 'Adventure'],
        mediaItem: MediaItem(
          id: 693134,
          imdbId: 'tt15239678',
          title: 'Dune: Part Two',
          overview:
              'Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a path of revenge against the conspirators who destroyed his family.',
          posterPath: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
          backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520b4.jpg',
          voteAverage: 8.3,
          releaseDate: '2024-03-01',
          type: MediaType.movie,
          tagline: 'Long live the fighters.',
          runtimeMinutes: 166,
        ),
      ),
      const ClipItem(
        id: 'clip_series_94605',
        mediaId: 94605,
        title: 'Arcane',
        overview:
            'Set in the utopian region of Piltover and the oppressed underground of Zaun, the story follows the origins of two iconic League champions-and the power that will tear them apart.',
        videoKey: 'fXmAurh012s',
        posterPath: '/abf8tZvngYjGlSr00m0UrkLJg49.jpg',
        backdropPath: '/fqv8v6AycXKsivp1T5yKtLbGXce.jpg',
        voteAverage: 8.7,
        releaseYear: '2021',
        mediaType: MediaType.series,
        genres: ['Animation', 'Sci-Fi', 'Action'],
        mediaItem: MediaItem(
          id: 94605,
          imdbId: 'tt1190634',
          title: 'Arcane',
          overview:
              'Set in the utopian region of Piltover and the oppressed underground of Zaun, the story follows the origins of two iconic League champions-and the power that will tear them apart.',
          posterPath: '/abf8tZvngYjGlSr00m0UrkLJg49.jpg',
          backdropPath: '/fqv8v6AycXKsivp1T5yKtLbGXce.jpg',
          voteAverage: 8.7,
          releaseDate: '2021-11-06',
          type: MediaType.series,
          tagline: 'Every legend has a beginning.',
        ),
      ),
      const ClipItem(
        id: 'clip_movie_157336',
        mediaId: 157336,
        title: 'Interstellar',
        overview:
            'The adventures of a group of explorers who make use of a newly discovered wormhole to surpass the limitations on human space travel and conquer the vast distances involved in an interstellar voyage.',
        videoKey: 'zSWdZVtXT7E',
        posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        backdropPath: '/rAiYTsqzrxtvoUw8TEFeLqvAlOT.jpg',
        voteAverage: 8.4,
        releaseYear: '2014',
        mediaType: MediaType.movie,
        genres: ['Adventure', 'Drama', 'Sci-Fi'],
        mediaItem: MediaItem(
          id: 157336,
          imdbId: 'tt0816692',
          title: 'Interstellar',
          overview:
              'The adventures of a group of explorers who make use of a newly discovered wormhole to surpass the limitations on human space travel and conquer the vast distances involved in an interstellar voyage.',
          posterPath: '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
          backdropPath: '/rAiYTsqzrxtvoUw8TEFeLqvAlOT.jpg',
          voteAverage: 8.4,
          releaseDate: '2014-11-05',
          type: MediaType.movie,
          tagline: 'Mankind was born on Earth. It was never meant to die here.',
          runtimeMinutes: 169,
        ),
      ),
    ];
  }
}
