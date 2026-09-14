import 'package:equatable/equatable.dart';

enum StreamSourceType {
  directHttp,
  hls,
  dash,
  debrid,
  torrentSequential,
}

class ResolvedStream extends Equatable {
  final String streamUrl;
  final StreamSourceType sourceType;
  final Map<String, String>? httpHeaders;
  final String? title;
  final String? quality;
  final bool isSeekable;

  const ResolvedStream({
    required this.streamUrl,
    required this.sourceType,
    this.httpHeaders,
    this.title,
    this.quality,
    this.isSeekable = true,
  });

  @override
  List<Object?> get props => [streamUrl, sourceType, httpHeaders, title, quality, isSeekable];
}

abstract class StreamEngine {
  /// Unique identifier for the engine implementation.
  String get engineId;

  /// Whether this engine is supported on the current target platform.
  bool get isSupported;

  /// Initializes the streaming engine resources if needed.
  Future<void> initialize();

  /// Resolves the raw stream request into a playable HTTPS/file URL.
  Future<ResolvedStream> resolveStream({
    required String rawUrlOrInfoHash,
    Map<String, dynamic>? extraParams,
  });

  /// Releases resources allocated for the engine.
  Future<void> dispose();
}
