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
    if (combined.contains('4k') || combined.contains('2160p') || combined.contains('uhd')) {
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
  bool get isDirectHttp => url != null && (url!.startsWith('http://') || url!.startsWith('https://'));

  factory AddonStream.fromJson(Map<String, dynamic> json, {String? addonName}) {
    Map<String, String>? parsedHeaders;
    final rawBehaviorHints = json['behaviorHints'];
    if (rawBehaviorHints is Map<String, dynamic> && rawBehaviorHints['proxyHeaders'] is Map) {
      final reqHeaders = rawBehaviorHints['proxyHeaders']['request'] as Map?;
      if (reqHeaders != null) {
        parsedHeaders = reqHeaders.map((k, v) => MapEntry(k.toString(), v.toString()));
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
  List<Object?> get props => [name, title, url, infoHash, fileIdx, addonName, headers];
}
