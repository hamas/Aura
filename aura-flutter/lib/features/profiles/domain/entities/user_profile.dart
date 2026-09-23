import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String avatarPath;
  final String avatarPaletteId;
  final String? pinHash;
  final bool isPrimary;
  final bool isKids;
  final String maxAgeRating;
  final String displayLanguage;
  final String audioLanguage;
  final String subtitleLanguage;
  final String subtitleSize;
  final bool autoPlayNext;
  final bool autoPlayPreviews;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarPath = '',
    this.avatarPaletteId = 'electric_violet',
    this.pinHash,
    this.isPrimary = false,
    this.isKids = false,
    this.maxAgeRating = 'NC-17',
    this.displayLanguage = 'English',
    this.audioLanguage = 'English',
    this.subtitleLanguage = 'English',
    this.subtitleSize = '100%',
    this.autoPlayNext = true,
    this.autoPlayPreviews = true,
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

  /// Generate 1-2 character profile initials from name
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'A';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? avatarPaletteId,
    String? pinHash,
    bool? isPrimary,
    bool? isKids,
    String? maxAgeRating,
    String? displayLanguage,
    String? audioLanguage,
    String? subtitleLanguage,
    String? subtitleSize,
    bool? autoPlayNext,
    bool? autoPlayPreviews,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarPaletteId: avatarPaletteId ?? this.avatarPaletteId,
      pinHash: pinHash ?? this.pinHash,
      isPrimary: isPrimary ?? this.isPrimary,
      isKids: isKids ?? this.isKids,
      maxAgeRating: maxAgeRating ?? this.maxAgeRating,
      displayLanguage: displayLanguage ?? this.displayLanguage,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      autoPlayPreviews: autoPlayPreviews ?? this.autoPlayPreviews,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarPath,
        avatarPaletteId,
        pinHash,
        isPrimary,
        isKids,
        maxAgeRating,
        displayLanguage,
        audioLanguage,
        subtitleLanguage,
        subtitleSize,
        autoPlayNext,
        autoPlayPreviews,
        createdAt,
      ];
}

class ProfileAvatarPalette {
  static const List<Map<String, dynamic>> curatedPalettes = [
    {
      'id': 'electric_violet',
      'name': 'Electric Violet',
      'colors': [0xFF8A2BE2, 0xFF4A00E0],
    },
    {
      'id': 'neon_cyan',
      'name': 'Neon Cyan',
      'colors': [0xFF00F2FE, 0xFF4FACFE],
    },
    {
      'id': 'sunset_orange',
      'name': 'Sunset Orange',
      'colors': [0xFFFF0844, 0xFFFFB199],
    },
    {
      'id': 'emerald_gold',
      'name': 'Emerald Gold',
      'colors': [0xFF11998E, 0xFF38EF7D],
    },
    {
      'id': 'crimson_dark',
      'name': 'Crimson Dark',
      'colors': [0xFFED213A, 0xFF93291E],
    },
  ];
}

class KidsCertification {
  static const allowedRatings = {'G', 'PG', 'TV-Y', 'TV-Y7', 'TV-G', 'TV-PG'};

  static bool isAllowed(String rating) {
    return allowedRatings.contains(rating.toUpperCase());
  }
}
