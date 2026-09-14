import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura/features/profiles/domain/entities/user_profile.dart';

class ProfileManager {
  static const String _profilesKey = 'aura_household_profiles';
  static const String _activeProfileIdKey = 'aura_active_profile_id';
  static const int maxProfiles = 4;

  final SharedPreferences _prefs;
  final _profileStreamController = StreamController<UserProfile?>.broadcast();

  ProfileManager(this._prefs) {
    _ensureDefaultProfile();
  }

  Stream<UserProfile?> get activeProfileStream =>
      _profileStreamController.stream;

  List<UserProfile> getProfiles() {
    final rawJson = _prefs.getString(_profilesKey);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) =>
              UserProfile.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  UserProfile getActiveProfile() {
    final profiles = getProfiles();
    final activeId = _prefs.getString(_activeProfileIdKey);
    if (profiles.isEmpty) {
      final defaultProfile = UserProfile(
        id: 'default_owner',
        name: 'Primary Account',
        avatarPath: 'assets/avatars/avatar_1.png',
        isKids: false,
        createdAt: DateTime.now(),
      );
      saveProfile(defaultProfile);
      setActiveProfile(defaultProfile.id);
      return defaultProfile;
    }
    return profiles.firstWhere(
      (p) => p.id == activeId,
      orElse: () => profiles.first,
    );
  }

  Future<void> _ensureDefaultProfile() async {
    if (getProfiles().isEmpty) {
      getActiveProfile();
    }
  }

  Future<bool> saveProfile(UserProfile profile) async {
    final profiles = getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);

    if (index >= 0) {
      profiles[index] = profile;
    } else {
      if (profiles.length >= maxProfiles) return false;
      profiles.add(profile);
    }

    final encoded = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await _prefs.setString(_profilesKey, encoded);

    final activeId = _prefs.getString(_activeProfileIdKey);
    if (activeId == profile.id || activeId == null) {
      await setActiveProfile(profile.id);
    }
    return true;
  }

  Future<void> setActiveProfile(String profileId) async {
    await _prefs.setString(_activeProfileIdKey, profileId);
    final active = getActiveProfile();
    _profileStreamController.add(active);
  }

  Future<bool> deleteProfile(String profileId) async {
    final profiles = getProfiles();
    if (profiles.length <= 1) return false; // Prevent deleting sole profile
    profiles.removeWhere((p) => p.id == profileId);
    final encoded = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await _prefs.setString(_profilesKey, encoded);

    if (_prefs.getString(_activeProfileIdKey) == profileId) {
      await setActiveProfile(profiles.first.id);
    }
    return true;
  }

  void dispose() {
    _profileStreamController.close();
  }
}
