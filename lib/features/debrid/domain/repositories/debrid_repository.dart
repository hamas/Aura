import '../entities/debrid_account.dart';

abstract class DebridRepository {
  /// Check if the user has an active Real-Debrid API token set.
  Future<bool> hasValidToken();

  /// Save or update user API token.
  Future<void> saveApiToken(String token);

  /// Fetch user Real-Debrid account profile.
  Future<DebridAccount> getAccountDetails();

  /// Unrestrict a magnet URI, torrent info hash, or hoster link to a direct HTTPS video stream.
  Future<String> unrestrictMagnetOrHash(String magnetOrInfoHash,
      {int? fileIndex});

  /// Unrestrict a direct link or hoster URL to a direct CDN video stream.
  Future<String> unrestrictLink(String link);

  /// Remove stored API token.
  Future<void> removeToken();
}
