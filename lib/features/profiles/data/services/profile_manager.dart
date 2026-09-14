import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';

class ProfileManager {
  static const String _profilesKey = 'aura_user_profiles_v1';
  static const String _activeProfileIdKey = 'aura_active_profile_id';
  static const int maxProfiles = 4;
  final SharedPreferences _prefs;

  ProfileManager(this._prefs);

  List<UserProfile> getProfiles() {
    final rawJson = _prefs.getString(_profilesKey);
    if (rawJson == null || rawJson.isEmpty) {
      final defaultProfile = UserProfile(
        id: 'default_adult',
        name: 'Primary Account',
        avatarPath: '',
        isKids: false,
        createdAt: DateTime.now(),
      );
      _saveProfilesSync([defaultProfile]);
      _prefs.setString(_activeProfileIdKey, defaultProfile.id);
      return [defaultProfile];
    }

    final List<dynamic> list = jsonDecode(rawJson) as List<dynamic>;
    return list
        .map((item) => UserProfileModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  UserProfile? getActiveProfile() {
    final profiles = getProfiles();
    final activeId = _prefs.getString(_activeProfileIdKey);
    if (activeId == null) return profiles.firstOrNull;
    return profiles.firstWhere((p) => p.id == activeId,
        orElse: () => profiles.first);
  }

  Future<bool> setActiveProfile(String profileId) async {
    return await _prefs.setString(_activeProfileIdKey, profileId);
  }

  Future<bool> saveProfile(UserProfile profile) async {
    final profiles = getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);

    if (index < 0 && profiles.length >= maxProfiles) {
      return false; // Reached max profile limit
    }

    final updatedList = List<UserProfile>.from(profiles);
    if (index >= 0) {
      updatedList[index] = profile;
    } else {
      updatedList.add(profile);
    }

    final jsonList = updatedList
        .map((p) => UserProfileModel.fromEntity(p).toJson())
        .toList();
    return await _prefs.setString(_profilesKey, jsonEncode(jsonList));
  }

  Future<bool> deleteProfile(String profileId) async {
    final profiles = getProfiles();
    if (profiles.length <= 1) {
      return false;
    }

    final updatedList = profiles.where((p) => p.id != profileId).toList();
    final jsonList = updatedList
        .map((p) => UserProfileModel.fromEntity(p).toJson())
        .toList();
    final res = await _prefs.setString(_profilesKey, jsonEncode(jsonList));

    final activeId = _prefs.getString(_activeProfileIdKey);
    if (activeId == profileId) {
      await setActiveProfile(updatedList.first.id);
    }
    return res;
  }

  void _saveProfilesSync(List<UserProfile> profiles) {
    final jsonList =
        profiles.map((p) => UserProfileModel.fromEntity(p).toJson()).toList();
    _prefs.setString(_profilesKey, jsonEncode(jsonList));
  }
}
