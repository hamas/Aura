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
      createdAt: entity.createdAt,
    );
  }
}
