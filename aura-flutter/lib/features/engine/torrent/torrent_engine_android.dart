import 'dart:io';
import '../common/stream_engine.dart';
import 'local_torrent_stream_server.dart';

/// Android & Desktop implementation with sequential P2P torrent streaming.
/// Spawns a local sequential HTTP proxy server on 127.0.0.1.
class TorrentEngine implements StreamEngine {
  final LocalTorrentStreamServer _streamServer =
      LocalTorrentStreamServer.instance;
  bool _isInitialized = false;

  @override
  String get engineId => 'torrent_engine_io';

  @override
  bool get isSupported =>
      Platform.isAndroid ||
      Platform.isLinux ||
      Platform.isWindows ||
      Platform.isMacOS;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _streamServer.start();
    _isInitialized = true;
  }

  @override
  Future<ResolvedStream> resolveStream({
    required String rawUrlOrInfoHash,
    Map<String, dynamic>? extraParams,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final title = extraParams?['title'] as String?;
    final quality = extraParams?['quality'] as String?;
    final fileSize = extraParams?['fileSize'] as int?;

    // Convert infoHash to local sequential proxy stream
    final localProxyUrl = _streamServer.getOrStartProxyStream(
      magnetOrHash: rawUrlOrInfoHash,
      title: title,
      fileSize: fileSize,
    );

    return ResolvedStream(
      streamUrl: localProxyUrl,
      sourceType: StreamSourceType.torrentSequential,
      title: title ?? 'Torrent Stream',
      quality: quality ?? '1080p',
      isSeekable: true,
      httpHeaders: const {
        'User-Agent': 'Aura-Client/1.0',
        'Accept': '*/*',
      },
    );
  }

  @override
  Future<void> dispose() async {
    _streamServer.stopActiveStream();
  }
}
