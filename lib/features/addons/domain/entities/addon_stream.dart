import 'package:equatable/equatable.dart';

class AddonStream extends Equatable {
  final String? name;
  final String? title;
  final String? url;
  final String? infoHash;
  final int? fileIdx;
  final String? behaviorHints;
  final String? addonName;
  final Map<String, String>? headers;

  const AddonStream({
    this.name,
    this.title,
    this.url,
    this.infoHash,
    this.fileIdx,
    this.behaviorHints,
    this.addonName,
    this.headers,
  });

  /// Extracts resolution (4K, 1080p, 720p, etc.) from title/name
  String get resolution {
    final combined = '${name ?? ''} ${title ?? ''}'.toLowerCase();
    if (combined.contains('4k') ||
        combined.contains('2160p') ||
        combined.contains('uhd')) {
      return '4K UHD';
    } else if (combined.contains('1080p') || combined.contains('fhd')) {
      return '1080p';
    } else if (combined.contains('720p') || combined.contains('hd')) {
      return '720p';
    } else if (combined.contains('480p') || combined.contains('sd')) {
      return '480p';
    }
    return 'HD';
  }

  /// Whether this stream is a torrent/infoHash stream
  bool get isTorrent => infoHash != null && infoHash!.isNotEmpty;

  /// Whether this stream is a direct HTTP stream
  bool get isDirectHttp =>
      url != null &&
      (url!.startsWith('http://') || url!.startsWith('https://'));

  /// Whether this stream is instantly cached on Debrid or direct HTTP
  bool get isCached {
    final combined = '${name ?? ''} ${title ?? ''}'.toLowerCase();
    return combined.contains('⚡') ||
        combined.contains('[rd+]') ||
        combined.contains('cached') ||
        combined.contains('instant') ||
        combined.contains('realdebrid') ||
        combined.contains('rd+') ||
        combined.contains('debrid') ||
        isDirectHttp;
  }

  /// Whether this stream uses an efficient high-fidelity video codec (HEVC/H.265/AV1)
  bool get isHevc {
    final combined = '${name ?? ''} ${title ?? ''}'.toLowerCase();
    return combined.contains('hevc') ||
        combined.contains('h.265') ||
        combined.contains('h265') ||
        combined.contains('x265') ||
        combined.contains('av1');
  }

  /// Whether this stream includes spatial/multichannel audio (Atmos/5.1/7.1/TrueHD/DTS)
  bool get hasSpatialAudio {
    final combined = '${name ?? ''} ${title ?? ''}'.toLowerCase();
    return combined.contains('atmos') ||
        combined.contains('5.1') ||
        combined.contains('7.1') ||
        combined.contains('truehd') ||
        combined.contains('dts') ||
        combined.contains('dd+');
  }

  /// Parses file size in Gigabytes (GB) if present in title or name
  double? get fileSizeGB {
    final combined = '${name ?? ''} ${title ?? ''}';
    final gbMatch = RegExp(r'(\d+(?:\.\d+)?)\s*GB', caseSensitive: false)
        .firstMatch(combined);
    if (gbMatch != null) {
      return double.tryParse(gbMatch.group(1)!);
    }
    final mbMatch = RegExp(r'(\d+(?:\.\d+)?)\s*MB', caseSensitive: false)
        .firstMatch(combined);
    if (mbMatch != null) {
      final mb = double.tryParse(mbMatch.group(1)!);
      return mb != null ? mb / 1024.0 : null;
    }
    return null;
  }

  factory AddonStream.fromJson(Map<String, dynamic> json, {String? addonName}) {
    Map<String, String>? parsedHeaders;
    final rawBehaviorHints = json['behaviorHints'];
    if (rawBehaviorHints is Map<String, dynamic> &&
        rawBehaviorHints['proxyHeaders'] is Map) {
      final reqHeaders = rawBehaviorHints['proxyHeaders']['request'] as Map?;
      if (reqHeaders != null) {
        parsedHeaders =
            reqHeaders.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }

    return AddonStream(
      name: json['name'] as String?,
      title: json['title'] as String?,
      url: json['url'] as String?,
      infoHash: json['infoHash'] as String?,
      fileIdx: json['fileIdx'] as int?,
      behaviorHints: json['behaviorHints']?.toString(),
      addonName: addonName,
      headers: parsedHeaders,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'url': url,
        'infoHash': infoHash,
        'fileIdx': fileIdx,
        'addonName': addonName,
        'headers': headers,
      };

  @override
  List<Object?> get props =>
      [name, title, url, infoHash, fileIdx, addonName, headers];
}
