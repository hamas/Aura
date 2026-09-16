import 'common/stream_engine.dart';
import '../../core/errors/exceptions.dart';
import '../debrid/domain/repositories/debrid_repository.dart';

class HttpDebridEngine implements StreamEngine {
  final DebridRepository? _debridRepository;

  HttpDebridEngine({DebridRepository? debridRepository})
      : _debridRepository = debridRepository;

  @override
  String get engineId => 'http_debrid_engine';

  @override
  bool get isSupported =>
      true; // Supported on all platforms (including iOS App Store)

  @override
  Future<void> initialize() async {
    // Direct HTTP engine requires no heavy local socket servers.
  }

  @override
  Future<ResolvedStream> resolveStream({
    required String rawUrlOrInfoHash,
    Map<String, dynamic>? extraParams,
  }) async {
    final title = extraParams?['title'] as String?;
    final quality = extraParams?['quality'] as String?;
    final headers = extraParams?['headers'] as Map<String, String>?;

    // Check if it's already a direct playable HTTP(S) link
    if (rawUrlOrInfoHash.startsWith('http://') ||
        rawUrlOrInfoHash.startsWith('https://')) {
      final isHls = rawUrlOrInfoHash.contains('.m3u8');
      final isDash = rawUrlOrInfoHash.contains('.mpd');

      return ResolvedStream(
        streamUrl: rawUrlOrInfoHash,
        sourceType: isHls
            ? StreamSourceType.hls
            : isDash
                ? StreamSourceType.dash
                : StreamSourceType.directHttp,
        httpHeaders: headers,
        title: title,
        quality: quality,
      );
    }

    if (rawUrlOrInfoHash.isEmpty) {
      throw const DebridException(
          'Stream source is missing or invalid. Please select another stream result.');
    }

    // Check if infoHash provided but Debrid is missing token
    if (_isHexInfoHash(rawUrlOrInfoHash)) {
      if (_debridRepository == null) {
        throw const DebridException(
            'Debrid account not linked. Please configure Real-Debrid in Settings > Streaming.');
      }

      final hasToken = await _debridRepository.hasValidToken();
      if (!hasToken) {
        throw const DebridException(
            'Debrid API key missing. Please enter your Real-Debrid API token in Settings > Streaming.');
      }

      final unrestrictedUrl = await _debridRepository.unrestrictMagnetOrHash(
        rawUrlOrInfoHash,
        fileIndex: extraParams?['fileIdx'] as int?,
      );

      return ResolvedStream(
        streamUrl: unrestrictedUrl,
        sourceType: StreamSourceType.debrid,
        httpHeaders: headers,
        title: title ?? 'Debrid Stream',
        quality: quality,
      );
    }

    throw const DebridException(
        'Unable to resolve stream: Direct HTTP URL or configured Debrid account required.');
  }

  bool _isHexInfoHash(String str) {
    return RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(str);
  }

  @override
  Future<void> dispose() async {}
}
