import 'dart:convert';
import 'package:http/http.dart' as http;
import 'trakt_auth_service.dart';

enum TraktScrobbleAction { start, pause, stop }

class TraktScrobbleService {
  final TraktAuthService _authService;
  final http.Client _client;

  TraktScrobbleService({
    TraktAuthService? authService,
    http.Client? client,
  })  : _authService = authService ?? TraktAuthService(),
        _client = client ?? http.Client();

  static bool shouldMarkWatched(double progressPercentage) {
    return progressPercentage >= 0.80;
  }

  Future<bool> scrobble({
    required TraktScrobbleAction action,
    required String mediaId,
    required double progressPercentage,
    String? title,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final progress = (progressPercentage * 100).clamp(0.0, 100.0);
    final endpoint = action.name; // start, pause, or stop

    final body = {
      'movie': {
        'title': title ?? 'Media $mediaId',
        'ids': {'tmdb': int.tryParse(mediaId) ?? 0},
      },
      'progress': progress,
    };

    try {
      final response = await _client.post(
        Uri.parse('${TraktAuthService.baseUrl}/scrobble/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.accessToken}',
          'trakt-api-version': '2',
          'trakt-api-key': _authService.clientId,
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
