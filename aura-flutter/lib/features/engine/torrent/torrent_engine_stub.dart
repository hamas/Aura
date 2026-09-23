import '../common/stream_engine.dart';
import '../../../core/errors/exceptions.dart';

/// Platform-safe stub implementation for iOS, Web, and unsupported targets.
/// Ensures App Store guideline compliance by completely excluding P2P dependencies.
class TorrentEngine implements StreamEngine {
  @override
  String get engineId => 'torrent_engine_stub';

  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {
    // No-op on iOS and Web
  }

  @override
  Future<ResolvedStream> resolveStream({
    required String rawUrlOrInfoHash,
    Map<String, dynamic>? extraParams,
  }) async {
    throw const AddonProtocolException(
      'P2P / Torrent streaming is not supported on this platform. Please use a Debrid provider or direct HTTPS stream.',
    );
  }

  @override
  Future<void> dispose() async {}
}
