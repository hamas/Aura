import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'common/stream_engine.dart';
import '../../core/errors/exceptions.dart';

class HttpDebridEngine implements StreamEngine {
  final Dio _dio;

  HttpDebridEngine({dynamic debridRepository, Dio? dio})
      : _dio = dio ??
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

  Future<String> _resolveRedirects(String url, {Map<String, String>? headers}) async {
    try {
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
        if (response.data is ResponseBody) {
          final resBody = response.data as ResponseBody;
          unawaited(resBody.stream.drain<dynamic>().catchError((_) {}));
        }
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
    debugPrint('DEBUG: [1] Entering resolveStream with: $rawUrlOrInfoHash');
    final title = extraParams?['title'] as String?;
    final quality = extraParams?['quality'] as String?;
    final headers = extraParams?['headers'] as Map<String, String>?;

    if (rawUrlOrInfoHash.isEmpty) {
      throw const ServerException(
          'Stream source is missing or invalid. Please select another stream result.');
    }

    final isHttp = rawUrlOrInfoHash.startsWith('http://') ||
        rawUrlOrInfoHash.startsWith('https://');

    if (!isHttp) {
      throw const ServerException(
          'Direct stream URL required. Magnet links require a direct web streaming gateway.');
    }

    final targetUrl = await _resolveRedirects(rawUrlOrInfoHash, headers: headers);
    final isHls = targetUrl.contains('.m3u8');
    final isDash = targetUrl.contains('.mpd');

    return ResolvedStream(
      streamUrl: targetUrl,
      sourceType: isHls
          ? StreamSourceType.hls
          : isDash
              ? StreamSourceType.dash
              : StreamSourceType.directHttp,
      httpHeaders: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        if (headers != null) ...headers,
      },
      title: title ?? 'Direct Stream',
      quality: quality,
    );
  }

  @override
  Future<void> dispose() async {}
}
