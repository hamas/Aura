import 'package:equatable/equatable.dart';

enum SubtitleEdgeStyle { dropShadow, solidBox }

enum SubtitleFontSize { small, medium, large }

class SubtitleTrackInfo extends Equatable {
  final String id;
  final String language;
  final String label;
  final String? url;
  final bool isSelected;

  const SubtitleTrackInfo({
    required this.id,
    required this.language,
    required this.label,
    this.url,
    this.isSelected = false,
  });

  @override
  List<Object?> get props => [id, language, label, url, isSelected];
}

class AudioTrackInfo extends Equatable {
  final String id;
  final String language;
  final String label;

  const AudioTrackInfo({
    required this.id,
    required this.language,
    required this.label,
  });

  @override
  List<Object?> get props => [id, language, label];
}
