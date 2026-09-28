import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/storage/secure_storage_service.dart';
import 'common/stream_engine.dart';
import '../../core/errors/exceptions.dart';

class HttpDebridEngine implements StreamEngine {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  HttpDebridEngine({
    dynamic debridRepository,
    Dio? dio,
    SecureStorageService? secureStorage,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              sendTimeout: const Duration(seconds: 4),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
            )),
        _secureStorage = secureStorage ?? SecureStorageService();

  @override
  String get engineId => 'http_debrid_engine';

  @override
  bool get isSupported => true;

  @override
  Future<void> initialize() async {}



  @override
  Future<ResolvedStream> resolveStream({
    required String rawUrlOrInfoHash,
    Map<String, dynamic>? extraParams,
  }) async {
    debugPrint('DEBUG: [1] Entering resolveStream with: $rawUrlOrInfoHash');
    final title = extraParams?['title'] as String?;
    final quality = extraParams?['quality'] as String?;
    final headers = <String, String>{
      if (extraParams?['headers'] is Map<String, String>)
        ...(extraParams!['headers'] as Map<String, String>),
    };

    if (rawUrlOrInfoHash.isEmpty) {
      throw const ServerException(
          'Stream source is missing or invalid. Please select another stream result.');
    }

    final isHttp = rawUrlOrInfoHash.startsWith('http://') ||
        rawUrlOrInfoHash.startsWith('https://');

    if (!isHttp) {
      // 1. Try Real-Debrid API resolution if user has configured Real-Debrid API key
      try {
        final rdKey = await _secureStorage.getRealDebridApiKey();
        if (rdKey != null && rdKey.isNotEmpty) {
          final magnet = rawUrlOrInfoHash.startsWith('magnet:')
              ? rawUrlOrInfoHash
              : 'magnet:?xt=urn:btih:$rawUrlOrInfoHash';

          // Add magnet to Real-Debrid
          final addRes = await _dio.post<Map<String, dynamic>>(
            'https://api.real-debrid.com/rest/1.0/torrents/addMagnet',
            data: {'magnet': magnet},
            options: Options(
              headers: {'Authorization': 'Bearer $rdKey'},
              contentType: Headers.formUrlEncodedContentType,
            ),
          );

          final torrentId = addRes.data?['id']?.toString();
          if (torrentId != null && torrentId.isNotEmpty) {
            // Select all files
            await _dio.post<dynamic>(
              'https://api.real-debrid.com/rest/1.0/torrents/selectFiles/$torrentId',
              data: {'files': 'all'},
              options: Options(
                headers: {'Authorization': 'Bearer $rdKey'},
                contentType: Headers.formUrlEncodedContentType,
              ),
            );

            // Fetch torrent details to retrieve unrestricted link
            final infoRes = await _dio.get<Map<String, dynamic>>(
              'https://api.real-debrid.com/rest/1.0/torrents/info/$torrentId',
              options: Options(headers: {'Authorization': 'Bearer $rdKey'}),
            );

            final links = infoRes.data?['links'] as List<dynamic>?;
            if (links != null && links.isNotEmpty) {
              final unrestrictRes = await _dio.post<Map<String, dynamic>>(
                'https://api.real-debrid.com/rest/1.0/unrestrict/link',
                data: {'link': links.first.toString()},
                options: Options(
                  headers: {'Authorization': 'Bearer $rdKey'},
                  contentType: Headers.formUrlEncodedContentType,
                ),
              );

              final downloadUrl = unrestrictRes.data?['download']?.toString();
              if (downloadUrl != null && downloadUrl.startsWith('http')) {
                return ResolvedStream(
                  streamUrl: downloadUrl,
                  sourceType: StreamSourceType.directHttp,
                  title: title ?? 'Real-Debrid Direct Stream',
                  quality: quality,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('RealDebrid resolution fallback warning: $e');
      }

      // 2. Fallback to TorrentEngine local proxy
      final fileIdx = extraParams?['fileIdx'] as int? ?? 0;
      final infoHash = rawUrlOrInfoHash.startsWith('magnet:')
          ? RegExp(r'btih:([a-zA-Z0-9]+)').firstMatch(rawUrlOrInfoHash)?.group(1) ?? rawUrlOrInfoHash
          : rawUrlOrInfoHash;

      return ResolvedStream(
        streamUrl: 'http://127.0.0.1:8088/stream/$infoHash/$fileIdx',
        sourceType: StreamSourceType.torrentSequential,
        title: title ?? 'Torrent P2P Stream',
        quality: quality,
      );
    }

    // Attach stored Real-Debrid / TorBox credentials if matching domain and header missing
    if (!headers.containsKey('Authorization')) {
      try {
        if (rawUrlOrInfoHash.contains('real-debrid')) {
          final rdKey = await _secureStorage.getRealDebridApiKey();
          if (rdKey != null && rdKey.isNotEmpty) {
            headers['Authorization'] = 'Bearer $rdKey';
          }
        } else if (rawUrlOrInfoHash.contains('torbox')) {
          final tbKey = await _secureStorage.getTorBoxApiKey();
          if (tbKey != null && tbKey.isNotEmpty) {
            headers['Authorization'] = 'Bearer $tbKey';
          }
        }
      } catch (_) {
        // Safe fallback if secure storage is unavailable or in isolated unit test
      }
    }

    final targetUrl = rawUrlOrInfoHash;
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
        ...headers,
      },
      title: title ?? 'Direct Stream',
      quality: quality,
    );
  }

  @override
  Future<void> dispose() async {}
}
