import 'package:equatable/equatable.dart';
import 'addon_manifest.dart';

enum AddonPresetType {
  freeCommunity,
  openSubtitles,
}

class CommunityAddonPreset extends Equatable {
  final String id;
  final String name;
  final String description;
  final String manifestUrl;
  final AddonPresetType type;
  final String badgeText;
  final bool isFreeNoAccount;
  final AddonManifest manifest;

  const CommunityAddonPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.manifestUrl,
    required this.type,
    required this.badgeText,
    required this.isFreeNoAccount,
    required this.manifest,
  });

  static const CommunityAddonPreset freeCommunityEngine = CommunityAddonPreset(
    id: 'community_free_stream_engine',
    name: 'Free Community Engine',
    description:
        'Instant 1-tap streaming. Resolves open web HTTPS & HLS streams with zero accounts or API keys required.',
    manifestUrl: 'https://v3-cinemeta.strem.io/manifest.json',
    type: AddonPresetType.freeCommunity,
    badgeText: '100% Free • No Account',
    isFreeNoAccount: true,
    manifest: AddonManifest(
      id: 'community_free_stream_engine',
      name: 'Free Community Engine',
      version: '1.2.0',
      description:
          'Resolves open HTTPS & HLS video streams with zero accounts or API keys.',
      transportUrl: 'https://v3-cinemeta.strem.io/manifest.json',
      resources: ['stream', 'catalog'],
      types: ['movie', 'series'],
    ),
  );

  static const CommunityAddonPreset openSubtitlesEngine = CommunityAddonPreset(
    id: 'opensubtitles_v3',
    name: 'OpenSubtitles v3',
    description: 'Provides multilingual community subtitles for video playback.',
    manifestUrl: 'https://v3-subtitles.strem.io/manifest.json',
    type: AddonPresetType.openSubtitles,
    badgeText: 'Subtitles • Utility',
    isFreeNoAccount: true,
    manifest: AddonManifest(
      id: 'opensubtitles_v3',
      name: 'OpenSubtitles v3',
      version: '3.0.0',
      description: 'Multilingual subtitles for movies and TV series.',
      transportUrl: 'https://v3-subtitles.strem.io/manifest.json',
      resources: ['subtitles'],
      types: ['movie', 'series'],
    ),
  );

  /// Fallback open HLS stream preset for zero-network testing
  static const String fallbackOpenHlsStreamUrl =
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

  /// Live hosted Stremio community add-on web directory
  static const String communityDirectoryUrl =
      'https://hamas.github.io/Aura/';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        manifestUrl,
        type,
        badgeText,
        isFreeNoAccount,
        manifest,
      ];
}
