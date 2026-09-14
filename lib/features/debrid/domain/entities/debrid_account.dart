import 'package:equatable/equatable.dart';

class DebridAccount extends Equatable {
  final String username;
  final String email;
  final int points;
  final String type; // 'premium' or 'free'
  final DateTime? expirationDate;

  const DebridAccount({
    required this.username,
    required this.email,
    required this.points,
    required this.type,
    this.expirationDate,
  });

  bool get isPremium => type == 'premium';

  int get premiumDaysLeft {
    if (expirationDate == null) return 0;
    final diff = expirationDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory DebridAccount.fromJson(Map<String, dynamic> json) {
    return DebridAccount(
      username: json['username'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      type: json['type'] as String? ?? 'free',
      expirationDate: json['expiration'] != null
          ? DateTime.tryParse(json['expiration'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [username, email, points, type, expirationDate, isPremium];
}
