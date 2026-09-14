import 'package:aura/features/addons/domain/entities/addon_stream.dart';
import 'package:aura/features/player/domain/services/smart_stream_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmartStreamSelector Unit Tests', () {
    const selector = SmartStreamSelector();

    const cached1080pStream = AddonStream(
      name: '[RD+] Real-Debrid',
      title: 'Movie.2024.1080p.WEB-DL.HEVC.Atmos.2.5GB.mkv ⚡',
      url: 'https://debrid.example.com/stream/movie1080p.mp4',
    );

    const uncached4kStream = AddonStream(
      name: 'Torrent',
      title: 'Movie.2024.2160p.UHD.REMUX.65GB.mkv',
      infoHash: 'abcdef1234567890abcdef1234567890abcdef12',
    );

    const cached4kHevcStream = AddonStream(
      name: '[RD+] Real-Debrid ⚡',
      title: 'Movie.2024.2160p.UHD.HEVC.Atmos.12.5GB.mkv',
      url: 'https://debrid.example.com/stream/movie4k.mp4',
    );

    const lowBitrateStream = AddonStream(
      name: '[RD+] Real-Debrid',
      title: 'Movie.2024.1080p.AAC.500MB.mp4 ⚡',
      url: 'https://debrid.example.com/stream/movielow.mp4',
    );

    test('isCached, isHevc, hasSpatialAudio and fileSizeGB parsing', () {
      expect(cached1080pStream.isCached, isTrue);
      expect(cached1080pStream.isHevc, isTrue);
      expect(cached1080pStream.hasSpatialAudio, isTrue);
      expect(cached1080pStream.fileSizeGB, equals(2.5));

      expect(uncached4kStream.isCached, isFalse);
      expect(uncached4kStream.fileSizeGB, equals(65.0));

      expect(lowBitrateStream.fileSizeGB, closeTo(0.488, 0.01));
    });

    test('prioritizes instant cached 4K HEVC stream over uncached 4K torrent',
        () {
      final streams = [uncached4kStream, cached4kHevcStream];
      final best = selector.selectBestStream(streams);

      expect(best, equals(cached4kHevcStream));
    });

    test('prioritizes cached 1080p HEVC stream over uncached 4K torrent', () {
      final streams = [uncached4kStream, cached1080pStream];
      final best = selector.selectBestStream(streams);

      expect(best, equals(cached1080pStream));
    });

    test('penalizes oversized files and low bitrate rips', () {
      final scoreNormal = selector.scoreStream(cached1080pStream);
      final scoreLowBitrate = selector.scoreStream(lowBitrateStream);

      expect(scoreNormal, greaterThan(scoreLowBitrate));
    });

    test('ranks streams in descending order of calculated score', () {
      final streams = [uncached4kStream, cached1080pStream, cached4kHevcStream];
      final ranked = selector.rankStreams(streams);

      expect(ranked.first, equals(cached4kHevcStream));
      expect(ranked.last, equals(uncached4kStream));
    });
  });
}
