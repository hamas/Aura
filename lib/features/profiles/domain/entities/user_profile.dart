import 'dart:convert';
import 'package:crypto/crypto.dart';

enum KidsCertification {
  g,
  pg,
  tvY,
  tvY7,
  tvG,
  tvPg;

  static const List<String> allowedRatings = [
    'G',
    'PG',
    'TV-Y',
    'TV-Y7',
    'TV-G',
    'TV-PG',
  ];

  static bool isAllowed(String? rating) {
    if (rating == null || rating.isEmpty) return true;
    final normalized = rating.trim().toUpperCase();
    return allowedRatings.contains(normalized);
  }
}

class UserProfile {
  final String id;
  final String name;
  final String avatarPath;
  final bool isKids;
  final String? pinHash;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarPath,
    this.isKids = false,
    this.pinHash,
    required this.createdAt,
  });

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  bool verifyPin(String pin) {
    if (pinHash == null) return true;
    return pinHash == hashPin(pin);
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarPath,
    bool? isKids,
    String? pinHash,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      isKids: isKids ?? this.isKids,
      pinHash: pinHash ?? this.pinHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'isKids': isKids,
      'pinHash': pinHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatarPath'] as String,
      isKids: json['isKids'] as bool? ?? false,
      pinHash: json['pinHash'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
