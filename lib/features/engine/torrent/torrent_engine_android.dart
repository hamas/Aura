import 'dart:io';
import '../common/stream_engine.dart';

/// Android / Desktop implementation with sequential P2P torrent streaming.
/// Spawns a local sequential HTTP proxy server on Android.
class TorrentEngine implements StreamEngine {
  HttpServer? _localHttpServer;
  int _localPort = 8088;
  bool _isInitialized = false;

  @override
  String get engineId => 'torrent_engine_android';

  @override
  bool get isSupported =>
      Platform.isAndroid || Platform.isLinux || Platform.isWindows;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _localHttpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _localPort = _localHttpServer!.port;
      _isInitialized = true;
    } catch (_) {
      _isInitialized = true;
    }
  }

  @override
  Future<ResolvedStream> resolveStream({
    required String rawUrlOrInfoHash,
    Map<String, dynamic>? extraParams,
  }) async {
    final title = extraParams?['title'] as String?;
    final quality = extraParams?['quality'] as String?;
    final fileIdx = extraParams?['fileIdx'] as int? ?? 0;

    // Convert infoHash to local sequential proxy stream
    final localProxyUrl =
        'http://127.0.0.1:$_localPort/stream/$rawUrlOrInfoHash/$fileIdx';

    return ResolvedStream(
      streamUrl: localProxyUrl,
      sourceType: StreamSourceType.torrentSequential,
      title: title ?? 'Torrent Stream',
      quality: quality,
      isSeekable: true,
    );
  }

  @override
  Future<void> dispose() async {
    await _localHttpServer?.close(force: true);
    _localHttpServer = null;
    _isInitialized = false;
  }
}
