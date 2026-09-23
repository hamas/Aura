import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineScrobbleVault {
  static const String _keyOfflineScrobbles = 'aura_offline_scrobbles_queue_v1';

  static Future<void> queueScrobble(
      Map<String, dynamic> scrobblePayload) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyOfflineScrobbles) ?? [];
    rawList.add(jsonEncode(scrobblePayload));
    await prefs.setStringList(_keyOfflineScrobbles, rawList);
  }

  static Future<List<Map<String, dynamic>>> getQueuedScrobbles() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyOfflineScrobbles) ?? [];
    return rawList
        .map((str) => jsonDecode(str) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOfflineScrobbles);
  }
}
