import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    super.avatarPath = '',
    super.pinHash,
    super.isKids,
    super.maxAgeRating,
    required super.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath:
          json['avatarPath'] as String? ?? json['avatarUrl'] as String? ?? '',
      pinHash: json['pinHash'] as String? ?? json['pinCode'] as String?,
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
      'pinHash': pinHash,
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
      pinHash: entity.pinHash,
      isKids: entity.isKids,
      maxAgeRating: entity.maxAgeRating,
      createdAt: entity.createdAt,
    );
  }
}
