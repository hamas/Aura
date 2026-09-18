import 'package:equatable/equatable.dart';

class AddonSubtitle extends Equatable {
  final String id;
  final String url;
  final String lang;

  const AddonSubtitle({
    required this.id,
    required this.url,
    required this.lang,
  });

  factory AddonSubtitle.fromJson(Map<String, dynamic> json) {
    return AddonSubtitle(
      id: json['id'] as String? ?? json['url'] as String? ?? '',
      url: json['url'] as String? ?? '',
      lang: json['lang'] as String? ?? json['language'] as String? ?? 'eng',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'lang': lang,
      };

  @override
  List<Object?> get props => [id, url, lang];
}
