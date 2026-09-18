import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/services/deep_link_service.dart';
import 'package:aura/features/addons/data/datasources/stremio_addon_api.dart';

void main() {
  group('Stremio Addon Deep Link & URL Parsing Tests', () {
    test('sanitizeManifestUrl converts stremio:// scheme to https://', () {
      const input = 'stremio://torrentio.strem.fun/manifest.json';
      final result = StremioAddonApi.sanitizeManifestUrl(input);
      expect(result, equals('https://torrentio.strem.fun/manifest.json'));
    });

    test('sanitizeManifestUrl appends /manifest.json if omitted', () {
      const input = 'https://v3-cinemeta.strem.io';
      final result = StremioAddonApi.sanitizeManifestUrl(input);
      expect(result, equals('https://v3-cinemeta.strem.io/manifest.json'));
    });

    test('sanitizeManifestUrl extracts encoded url query parameter from aura://', () {
      const input = 'aura://addon/install?url=https%3A%2F%2Fv3-cinemeta.strem.io%2Fmanifest.json';
      final result = StremioAddonApi.sanitizeManifestUrl(input);
      expect(result, equals('https://v3-cinemeta.strem.io/manifest.json'));
    });

    test('extractManifestUrl parses custom aura scheme URI', () {
      final uri = Uri.parse('aura://addon/install?url=https%3A%2F%2Ftorrentio.strem.fun%2Fmanifest.json');
      final result = DeepLinkService.extractManifestUrl(uri);
      expect(result, equals('https://torrentio.strem.fun/manifest.json'));
    });

    test('extractManifestUrl parses direct stremio scheme URI', () {
      final uri = Uri.parse('stremio://v3-cinemeta.strem.io/manifest.json');
      final result = DeepLinkService.extractManifestUrl(uri);
      expect(result, equals('https://v3-cinemeta.strem.io/manifest.json'));
    });

    test('extractManifestUrl returns null for non-addon URIs', () {
      final uri = Uri.parse('https://example.com/about');
      final result = DeepLinkService.extractManifestUrl(uri);
      expect(result, isNull);
    });
  });
}
