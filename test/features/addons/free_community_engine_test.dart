import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/addons/domain/entities/addon_preset.dart';

void main() {
  group('CommunityAddonPreset Unit Tests', () {
    test('freeCommunityEngine properties are correct', () {
      const preset = CommunityAddonPreset.freeCommunityEngine;

      expect(preset.id, equals('community_free_stream_engine'));
      expect(preset.name, equals('Free Community Engine'));
      expect(preset.isFreeNoAccount, isTrue);
      expect(preset.badgeText, contains('100% Free'));
      expect(preset.manifest.id, equals('community_free_stream_engine'));
      expect(preset.manifest.supportsResource('stream'), isTrue);
    });

    test('openSubtitlesEngine properties are correct', () {
      const preset = CommunityAddonPreset.openSubtitlesEngine;

      expect(preset.id, equals('opensubtitles_v3'));
      expect(preset.name, equals('OpenSubtitles v3'));
      expect(preset.manifest.supportsResource('subtitles'), isTrue);
    });

    test('debridHdEngine properties are correct', () {
      const preset = CommunityAddonPreset.debridHdEngine;

      expect(preset.id, equals('hd_engine'));
      expect(preset.isFreeNoAccount, isFalse);
      expect(preset.badgeText, contains('Debrid'));
    });
  });
}
