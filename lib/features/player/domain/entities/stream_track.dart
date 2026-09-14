import 'package:equatable/equatable.dart';

class AudioTrackInfo extends Equatable {
  final String id;
  final String? title;
  final String? language;

  const AudioTrackInfo({required this.id, this.title, this.language});

  @override
  List<Object?> get props => [id, title, language];
}

class SubtitleTrackInfo extends Equatable {
  final String id;
  final String? title;
  final String? language;

  const SubtitleTrackInfo({required this.id, this.title, this.language});

  @override
  List<Object?> get props => [id, title, language];
}
