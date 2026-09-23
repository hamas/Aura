import 'package:equatable/equatable.dart';

class AddonCatalog extends Equatable {
  final String type;
  final String id;
  final String name;

  const AddonCatalog({
    required this.type,
    required this.id,
    required this.name,
  });

  factory AddonCatalog.fromJson(Map<String, dynamic> json) {
    return AddonCatalog(
      type: json['type'] as String? ?? 'movie',
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
      };

  @override
  List<Object?> get props => [type, id, name];
}

class AddonManifest extends Equatable {
  final String id;
  final String name;
  final String version;
  final String description;
  final String transportUrl;
  final List<String> resources;
  final List<String> types;
  final List<AddonCatalog> catalogs;
  final String? icon;
  final String? background;
  final List<String> idPrefixes;
  final Map<String, dynamic>? behaviorHints;
  final bool isEnabled;

  const AddonManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.transportUrl,
    required this.resources,
    required this.types,
    this.catalogs = const [],
    this.idPrefixes = const [],
    this.behaviorHints,
    this.icon,
    this.background,
    this.isEnabled = true,
  });

  bool supportsResource(String resource) => resources.contains(resource);
  bool supportsType(String type) => types.contains(type);
  bool supportsIdPrefix(String id) =>
      idPrefixes.isEmpty || idPrefixes.any((prefix) => id.startsWith(prefix));

  factory AddonManifest.fromJson(Map<String, dynamic> json,
      {required String transportUrl}) {
    // Parse resources which can be either list of strings or list of objects in Stremio v3
    final rawResources = json['resources'] as List<dynamic>? ?? [];
    final resourcesList = <String>[];
    for (final r in rawResources) {
      if (r is String) {
        resourcesList.add(r);
      } else if (r is Map<String, dynamic> && r['name'] != null) {
        resourcesList.add(r['name'] as String);
      }
    }

    final rawCatalogs = json['catalogs'] as List<dynamic>? ?? [];
    final catalogsList = rawCatalogs
        .whereType<Map<String, dynamic>>()
        .map((c) => AddonCatalog.fromJson(c))
        .toList();

    return AddonManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Add-on',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String? ?? '',
      transportUrl: transportUrl,
      resources: resourcesList,
      types: (json['types'] as List<dynamic>? ?? ['movie', 'series'])
          .cast<String>(),
      catalogs: catalogsList,
      idPrefixes: (json['idPrefixes'] as List<dynamic>? ?? []).cast<String>(),
      behaviorHints: json['behaviorHints'] as Map<String, dynamic>?,
      icon: json['logo'] as String? ?? json['icon'] as String?,
      background: json['background'] as String?,
      isEnabled: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'transportUrl': transportUrl,
        'resources': resources,
        'types': types,
        'catalogs': catalogs.map((c) => c.toJson()).toList(),
        'idPrefixes': idPrefixes,
        'behaviorHints': behaviorHints,
        'logo': icon,
        'background': background,
        'isEnabled': isEnabled,
      };

  AddonManifest copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    String? transportUrl,
    List<String>? resources,
    List<String>? types,
    List<AddonCatalog>? catalogs,
    List<String>? idPrefixes,
    Map<String, dynamic>? behaviorHints,
    String? icon,
    String? background,
    bool? isEnabled,
  }) {
    return AddonManifest(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      transportUrl: transportUrl ?? this.transportUrl,
      resources: resources ?? this.resources,
      types: types ?? this.types,
      catalogs: catalogs ?? this.catalogs,
      idPrefixes: idPrefixes ?? this.idPrefixes,
      behaviorHints: behaviorHints ?? this.behaviorHints,
      icon: icon ?? this.icon,
      background: background ?? this.background,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        description,
        transportUrl,
        resources,
        types,
        catalogs,
        idPrefixes,
        behaviorHints,
        icon,
        background,
        isEnabled,
      ];
}
