import 'package:equatable/equatable.dart';

enum DebridProviderType {
  realDebrid('Real-Debrid', 'RD'),
  allDebrid('AllDebrid', 'AD'),
  premiumize('Premiumize', 'PM'),
  torBox('TorBox', 'TB');

  final String displayName;
  final String tag;
  const DebridProviderType(this.displayName, this.tag);
}

class DebridAccount extends Equatable {
  final DebridProviderType providerType;
  final String username;
  final String email;
  final int points;
  final String type; // 'premium' or 'free'
  final DateTime? expirationDate;
  final double? trafficRemainingGb;

  const DebridAccount({
    this.providerType = DebridProviderType.realDebrid,
    required this.username,
    required this.email,
    required this.points,
    required this.type,
    this.expirationDate,
    this.trafficRemainingGb,
  });

  bool get isPremium => type == 'premium';

  int get premiumDaysLeft {
    if (expirationDate == null) return 0;
    final diff = expirationDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory DebridAccount.fromJson(Map<String, dynamic> json,
      {DebridProviderType providerType = DebridProviderType.realDebrid}) {
    return DebridAccount(
      providerType: providerType,
      username:
          json['username'] as String? ?? json['user'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      type: json['type'] as String? ??
          (json['is_premium'] == true ? 'premium' : 'free'),
      expirationDate: json['expiration'] != null
          ? DateTime.tryParse(json['expiration'] as String)
          : (json['premium_until'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (json['premium_until'] as num).toInt() * 1000)
              : null),
      trafficRemainingGb: (json['traffic_remaining'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        providerType,
        username,
        email,
        points,
        type,
        expirationDate,
        trafficRemainingGb,
        isPremium
      ];
}
