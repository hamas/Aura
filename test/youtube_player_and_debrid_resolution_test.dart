import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/engine/common/stream_engine.dart';
import 'package:aura/features/engine/http_debrid_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Part 1: Stream Resolution Engine Tests', () {
    test('HttpDebridEngine resolves direct HTTP stream URLs cleanly', () async {
      final engine = HttpDebridEngine();

      const sampleUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      final resolved = await engine.resolveStream(
        rawUrlOrInfoHash: sampleUrl,
        extraParams: {
          'title': 'Test Movie',
          'quality': '1080p',
        },
      );

      expect(resolved.streamUrl, equals(sampleUrl));
      expect(resolved.sourceType, equals(StreamSourceType.directHttp));
      expect(resolved.httpHeaders?['User-Agent'], contains('Mozilla/5.0'));
      expect(resolved.title, equals('Test Movie'));
    });
  });
}
