import 'package:equatable/equatable.dart';

class DebridAccount extends Equatable {
  final String username;
  final String email;
  final int points;
  final String type; // 'premium' or 'free'
  final DateTime? expirationDate;
  final bool isPremium;

  const DebridAccount({
    required this.username,
    required this.email,
    required this.points,
    required this.type,
    this.expirationDate,
    required this.isPremium,
  });

  factory DebridAccount.fromJson(Map<String, dynamic> json) {
    return DebridAccount(
      username: json['username'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      type: json['type'] as String? ?? 'free',
      expirationDate: json['expiration'] != null
          ? DateTime.tryParse(json['expiration'] as String)
          : null,
      isPremium: (json['type'] as String? ?? '') == 'premium',
    );
  }

  @override
  List<Object?> get props => [username, email, points, type, expirationDate, isPremium];
}
