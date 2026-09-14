import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/addons/domain/entities/addon_manifest.dart';
import 'package:aura/features/addons/domain/entities/addon_stream.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/domain/entities/season_episode.dart';

void main() {
  group('Phase 2 - Stremio Add-on Protocol & Catalog Entity Tests', () {
    test(
        'MediaItem generates standardized IMDb Stremio IDs for movies and series',
        () {
      const movie = MediaItem(
        id: 550,
        imdbId: 'tt0137523',
        title: 'Fight Club',
        overview: 'An insomniac office worker...',
        type: MediaType.movie,
      );

      expect(movie.getStremioId(), equals('tt0137523'));

      const series = MediaItem(
        id: 94605,
        imdbId: 'tt11126994',
        title: 'Arcane',
        overview: 'Set in Piltover and Zaun...',
        type: MediaType.series,
      );

      expect(
          series.getStremioId(season: 1, episode: 1), equals('tt11126994:1:1'));
      expect(
          series.getStremioId(season: 2, episode: 6), equals('tt11126994:2:6'));
    });

    test(
        'Stremio AddonManifest parses v3 manifest JSON and validates resources and types',
        () {
      final manifestJson = <String, dynamic>{
        'id': 'org.stremio.torrentio',
        'name': 'Torrentio',
        'version': '1.0.10',
        'description': 'Torrents provider for movies and series',
        'resources': <String>['stream'],
        'types': <String>['movie', 'series'],
        'catalogs': <Map<String, dynamic>>[],
      };

      final manifest = AddonManifest.fromJson(
        manifestJson,
        transportUrl: 'https://torrentio.strem.fun/manifest.json',
      );

      expect(manifest.id, equals('org.stremio.torrentio'));
      expect(manifest.supportsResource('stream'), isTrue);
      expect(manifest.supportsType('movie'), isTrue);
      expect(manifest.supportsType('series'), isTrue);
      expect(manifest.supportsType('channel'), isFalse);
    });

    test('AddonStream parses 4K, 1080p, and Torrent infoHash headers', () {
      final streamJson = {
        'name': 'Torrentio 4K',
        'title':
            'Dune.Part.Two.2024.2160p.UHD.BluRay.x265.DTS-HD.MA.7.1-AURA\n💾 14.8 GB',
        'infoHash': 'a9b8c7d6e5f41234567890abcdef1234567890ab',
        'fileIdx': 0,
        'behaviorHints': {
          'proxyHeaders': {
            'request': {
              'User-Agent': 'AuraClient/1.0',
            }
          }
        }
      };

      final stream = AddonStream.fromJson(streamJson, addonName: 'Torrentio');

      expect(stream.resolution, equals('4K UHD'));
      expect(stream.isTorrent, isTrue);
      expect(stream.addonName, equals('Torrentio'));
      expect(stream.headers?['User-Agent'], equals('AuraClient/1.0'));
    });

    test('Season and Episode entity JSON deserialization', () {
      final seasonJson = {
        'id': 12345,
        'season_number': 1,
        'name': 'Season 1',
        'overview': 'The beginning of the saga',
        'episodes': [
          {
            'id': 991,
            'episode_number': 1,
            'season_number': 1,
            'name': 'Welcome to the Playground',
            'overview': 'Orphaned sisters Violet and Powder...',
            'vote_average': 8.9,
            'still_path': '/sample_still.jpg',
          }
        ]
      };

      final season = Season.fromJson(seasonJson);
      expect(season.seasonNumber, equals(1));
      expect(season.episodes.length, equals(1));
      expect(season.episodes.first.name, equals('Welcome to the Playground'));
      expect(season.episodes.first.episodeNumber, equals(1));
    });
  });
}
