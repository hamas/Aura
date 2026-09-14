import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String avatarPath;
  final String? pinHash;
  final bool isKids;
  final String maxAgeRating;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarPath = '',
    this.pinHash,
    this.isKids = false,
    this.maxAgeRating = 'NC-17',
    required this.createdAt,
  });

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  bool verifyPin(String inputPin) {
    if (!hasPin) return true;
    return hashPin(inputPin) == pinHash;
  }

  String get avatarUrl => avatarPath;

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? pinHash,
    bool? isKids,
    String? maxAgeRating,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      pinHash: pinHash ?? this.pinHash,
      isKids: isKids ?? this.isKids,
      maxAgeRating: maxAgeRating ?? this.maxAgeRating,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarPath,
        pinHash,
        isKids,
        maxAgeRating,
        createdAt,
      ];
}

class KidsCertification {
  static const allowedRatings = {'G', 'PG', 'TV-Y', 'TV-Y7', 'TV-G', 'TV-PG'};

  static bool isAllowed(String rating) {
    return allowedRatings.contains(rating.toUpperCase());
  }
}
