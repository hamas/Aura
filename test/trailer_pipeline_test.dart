import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/player/data/services/trailer_stream_resolver.dart';
import 'package:aura/features/catalog/presentation/widgets/components/ambient_backdrop_fallback.dart';

void main() {
  group('TrailerStreamResolver Unit Tests', () {
    test('extractVideoId parses standard YouTube URLs and standalone IDs', () {
      expect(
        YoutubeExplodeUtil.extractVideoId(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeExplodeUtil.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeExplodeUtil.extractVideoId('dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('resolveTrailerStream returns fallback gracefully on unavailable source', () async {
      final resolver = TrailerStreamResolver();
      final result = await resolver.resolveTrailerStream(
        title: 'NonExistentTestMovie123456',
        year: '1900',
        tmdbTrailerUrl: null,
      );
      expect(result.streamUrl, isNull);
      expect(result.source, TrailerSource.none);
    });
  });

  group('AmbientBackdropFallback Widget Tests', () {
    testWidgets('renders Ken Burns animated backdrop and preview indicator badge',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 280,
              child: AmbientBackdropFallback(
                backdropUrl: null,
                title: 'Dune: Part Two',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Trailer unavailable — showing preview backdrop'),
          findsOneWidget);
    });
  });
}
