import 'dart:io';
import '../common/stream_engine.dart';
import 'local_torrent_stream_server.dart';

/// Windows & Desktop High-Performance Local Torrent Streaming Engine.
/// Leverages the embedded [LocalTorrentStreamServer] loopback proxy
/// providing HTTP 206 Partial Content byte-range seeking for MediaKit (libmpv).
class WindowsTorrentEngine implements StreamEngine {
  final LocalTorrentStreamServer _streamServer =
      LocalTorrentStreamServer.instance;
  bool _isInitialized = false;

  @override
  String get engineId => 'windows_torrent_engine';

  @override
  bool get isSupported =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

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

    // Start local loopback proxy stream with HTTP 206 range capabilities
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
        'User-Agent': 'Aura-Windows-StreamClient/1.0',
        'Accept': '*/*',
      },
    );
  }

  /// Downloads full torrent stream directly to Windows disk vault.
  Future<File> downloadToVault({
    required String magnetOrHash,
    required String title,
    void Function(double progress, double speedMBps)? onProgress,
  }) {
    return _streamServer.downloadTorrentToVault(
      magnetOrHash: magnetOrHash,
      title: title,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> dispose() async {
    _streamServer.stopActiveStream();
  }
}
