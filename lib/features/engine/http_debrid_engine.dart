import 'dart:async';
import 'package:dio/dio.dart';
import 'common/stream_engine.dart';
import '../../core/errors/exceptions.dart';
import '../debrid/domain/repositories/debrid_repository.dart';

class HttpDebridEngine implements StreamEngine {
  final DebridRepository? _debridRepository;
  final Dio _dio;

  HttpDebridEngine({DebridRepository? debridRepository, Dio? dio})
      : _debridRepository = debridRepository,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              sendTimeout: const Duration(seconds: 4),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
            ));

  @override
  String get engineId => 'http_debrid_engine';

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {}

  bool _isDebridLandingUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('real-debrid.com/d/') ||
        lower.contains('1fichier.com') ||
        lower.contains('rapidgator.net') ||
        lower.contains('uploaded.net') ||
        lower.contains('turbobit.net') ||
        lower.contains('filefactory.com') ||
        lower.contains('mega.nz') ||
        lower.contains('nitroflare.com') ||
        lower.contains('katfile.com') ||
        lower.contains('ddownload.com') ||
        lower.contains('alfafile.net') ||
        lower.contains('uptobox.com');
  }

  Future<String> _resolveRedirects(String url, {Map<String, String>? headers}) async {
    try {
      // Use HEAD or streaming GET to follow redirects without downloading entire media
      Response<dynamic> response;
      try {
        response = await _dio.head(
          url,
          options: Options(
            followRedirects: true,
            maxRedirects: 6,
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
      } catch (_) {
        response = await _dio.get(
          url,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: true,
            maxRedirects: 6,
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
      }
      return response.realUri.toString();
    } catch (_) {
      return url;
    }
  }

  @override
  Future<ResolvedStream> resolveStream({
    required String rawUrlOrInfoHash,
    Map<String, dynamic>? extraParams,
  }) async {
    final title = extraParams?['title'] as String?;
    final quality = extraParams?['quality'] as String?;
    final headers = extraParams?['headers'] as Map<String, String>?;
    final fileIdx = (extraParams?['fileIdx'] ?? extraParams?['fileIndex']) as int?;

    if (rawUrlOrInfoHash.isEmpty) {
      throw const DebridException(
          'Stream source is missing or invalid. Please select another stream result.');
    }

    final hasDebrid =
        _debridRepository != null && await _debridRepository.hasValidToken();

    String targetUrl = rawUrlOrInfoHash;

    // 1. Non-HTTP inputs: Torrent InfoHash or Magnet URI
    if (!rawUrlOrInfoHash.startsWith('http://') &&
        !rawUrlOrInfoHash.startsWith('https://')) {
      if (hasDebrid) {
        targetUrl = await _debridRepository.unrestrictMagnetOrHash(
          rawUrlOrInfoHash,
          fileIndex: fileIdx,
        ).timeout(
          const Duration(seconds: 7),
          onTimeout: () => throw const DebridException(
              'Real-Debrid stream resolution timed out. Please try another stream.'),
        );
      } else {
        throw const DebridException(
            'Unable to resolve torrent stream: Configured Real-Debrid account required.');
      }
    } else {
      // 2. HTTP(S) input: Could be a direct link, Stremio proxy redirect, or Debrid landing page (/d/...)
      if (hasDebrid && _isDebridLandingUrl(rawUrlOrInfoHash)) {
        targetUrl = await _debridRepository.unrestrictLink(rawUrlOrInfoHash).timeout(
          const Duration(seconds: 4),
          onTimeout: () => rawUrlOrInfoHash,
        );
      } else {
        // Resolve redirects with a 3-second timeout fallback so network stalls never hang playback
        final redirectedUrl = await _resolveRedirects(rawUrlOrInfoHash, headers: headers)
            .timeout(const Duration(seconds: 3), onTimeout: () => rawUrlOrInfoHash);
        if (hasDebrid && _isDebridLandingUrl(redirectedUrl)) {
          targetUrl = await _debridRepository.unrestrictLink(redirectedUrl).timeout(
            const Duration(seconds: 4),
            onTimeout: () => redirectedUrl,
          );
        } else {
          targetUrl = redirectedUrl;
        }
      }
    }

    final isHls = targetUrl.contains('.m3u8');
    final isDash = targetUrl.contains('.mpd');

    return ResolvedStream(
      streamUrl: targetUrl,
      sourceType: (hasDebrid || targetUrl.contains('real-debrid'))
          ? StreamSourceType.debrid
          : (isHls
              ? StreamSourceType.hls
              : isDash
                  ? StreamSourceType.dash
                  : StreamSourceType.directHttp),
      httpHeaders: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        if (headers != null) ...headers,
      },
      title: title ?? 'HD Stream',
      quality: quality,
    );
  }

  @override
  Future<void> dispose() async {}
}
