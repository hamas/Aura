import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    super.avatarPath = '',
    super.avatarPaletteId = 'electric_violet',
    super.pinHash,
    super.isPrimary = false,
    super.isKids = false,
    super.maxAgeRating = 'NC-17',
    super.displayLanguage = 'English',
    super.audioLanguage = 'English',
    super.subtitleLanguage = 'English',
    super.subtitleSize = '100%',
    super.autoPlayNext = true,
    super.autoPlayPreviews = true,
    required super.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath:
          json['avatarPath'] as String? ?? json['avatarUrl'] as String? ?? '',
      avatarPaletteId: json['avatarPaletteId'] as String? ?? 'electric_violet',
      pinHash: json['pinHash'] as String? ?? json['pinCode'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      isKids: json['isKids'] as bool? ?? false,
      maxAgeRating: json['maxAgeRating'] as String? ?? 'NC-17',
      displayLanguage: json['displayLanguage'] as String? ?? 'English',
      audioLanguage: json['audioLanguage'] as String? ?? 'English',
      subtitleLanguage: json['subtitleLanguage'] as String? ?? 'English',
      subtitleSize: json['subtitleSize'] as String? ?? '100%',
      autoPlayNext: json['autoPlayNext'] as bool? ?? true,
      autoPlayPreviews: json['autoPlayPreviews'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'avatarPaletteId': avatarPaletteId,
      'pinHash': pinHash,
      'isPrimary': isPrimary,
      'isKids': isKids,
      'maxAgeRating': maxAgeRating,
      'displayLanguage': displayLanguage,
      'audioLanguage': audioLanguage,
      'subtitleLanguage': subtitleLanguage,
      'subtitleSize': subtitleSize,
      'autoPlayNext': autoPlayNext,
      'autoPlayPreviews': autoPlayPreviews,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      name: entity.name,
      avatarPath: entity.avatarPath,
      avatarPaletteId: entity.avatarPaletteId,
      pinHash: entity.pinHash,
      isPrimary: entity.isPrimary,
      isKids: entity.isKids,
      maxAgeRating: entity.maxAgeRating,
      displayLanguage: entity.displayLanguage,
      audioLanguage: entity.audioLanguage,
      subtitleLanguage: entity.subtitleLanguage,
      subtitleSize: entity.subtitleSize,
      autoPlayNext: entity.autoPlayNext,
      autoPlayPreviews: entity.autoPlayPreviews,
      createdAt: entity.createdAt,
    );
  }
}
