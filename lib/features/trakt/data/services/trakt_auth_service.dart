import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class TraktDeviceCodeResponse {
  final String deviceCode;
  final String userCode;
  final String verificationUrl;
  final int expiresIn;
  final int interval;

  const TraktDeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresIn,
    required this.interval,
  });

  factory TraktDeviceCodeResponse.fromJson(Map<String, dynamic> json) {
    return TraktDeviceCodeResponse(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUrl: json['verification_url'] as String,
      expiresIn: json['expires_in'] as int,
      interval: json['interval'] as int? ?? 5,
    );
  }
}

class TraktAuthToken {
  final String accessToken;
  final String refreshToken;
  final int createdAt;
  final int expiresIn;

  const TraktAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.createdAt,
    required this.expiresIn,
  });

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= (createdAt + expiresIn - 60); // 60s buffer
  }

  factory TraktAuthToken.fromJson(Map<String, dynamic> json) {
    return TraktAuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      createdAt: json['created_at'] as int? ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      expiresIn: json['expires_in'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'created_at': createdAt,
      'expires_in': expiresIn,
    };
  }
}

class TraktAuthService {
  static const String _tokenStorageKey = 'aura_trakt_auth_token';
  static const String baseUrl = 'https://api.trakt.tv';
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String clientId;
  final String clientSecret;

  TraktAuthService({
    FlutterSecureStorage? storage,
    http.Client? client,
    this.clientId = 'TRAKT_CLIENT_ID_PLACEHOLDER',
    this.clientSecret = 'TRAKT_CLIENT_SECRET_PLACEHOLDER',
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<TraktDeviceCodeResponse?> generateDeviceCode() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/oauth/device/code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'client_id': clientId}),
      );
      if (response.statusCode == 200) {
        return TraktDeviceCodeResponse.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map));
      }
    } catch (_) {}
    return null;
  }

  Future<TraktAuthToken?> pollForToken(String deviceCode,
      {int intervalSeconds = 5}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/oauth/device/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': deviceCode,
          'client_id': clientId,
          'client_secret': clientSecret,
        }),
      );
      if (response.statusCode == 200) {
        final token = TraktAuthToken.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map));
        await saveToken(token);
        return token;
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveToken(TraktAuthToken token) async {
    await _storage.write(
      key: _tokenStorageKey,
      value: jsonEncode(token.toJson()),
    );
  }

  Future<TraktAuthToken?> getToken() async {
    final raw = await _storage.read(key: _tokenStorageKey);
    if (raw == null) return null;
    try {
      final token = TraktAuthToken.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      if (token.isExpired) {
        return await refreshToken(token.refreshToken);
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<TraktAuthToken?> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/oauth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh_token': refreshToken,
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'refresh_token',
        }),
      );
      if (response.statusCode == 200) {
        final token = TraktAuthToken.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map));
        await saveToken(token);
        return token;
      }
    } catch (_) {}
    return null;
  }

  Future<void> disconnect() async {
    await _storage.delete(key: _tokenStorageKey);
  }
}
