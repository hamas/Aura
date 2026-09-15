import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';

class ProfileManager {
  static const String _profilesKey = 'aura_user_profiles_v1';
  static const String _activeProfileIdKey = 'aura_active_profile_id';
  static const int maxProfiles = 3;
  static ProfileManager? _instance;
  final SharedPreferences? _prefs;

  ProfileManager([this._prefs]);

  static Future<ProfileManager> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = ProfileManager(prefs);
    }
    return _instance!;
  }

  SharedPreferences get prefs => _prefs!;

  List<UserProfile> getProfiles() {
    final p = _prefs;
    if (p == null) return [];
    final rawJson = p.getString(_profilesKey);
    if (rawJson == null || rawJson.isEmpty) {
      final defaultProfile = UserProfile(
        id: 'profile_1',
        name: 'Profile 1',
        avatarPath: '',
        isPrimary: false,
        isKids: false,
        createdAt: DateTime.now(),
      );
      _saveProfilesSync([defaultProfile]);
      p.setString(_activeProfileIdKey, defaultProfile.id);
      return [defaultProfile];
    }

    final List<dynamic> list = jsonDecode(rawJson) as List<dynamic>;
    return list
        .map((item) => UserProfileModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  UserProfile? getActiveProfile() {
    final profiles = getProfiles();
    final p = _prefs;
    if (p == null) return profiles.firstOrNull;
    final activeId = p.getString(_activeProfileIdKey);
    if (activeId == null) return profiles.firstOrNull;
    return profiles.firstWhere((prof) => prof.id == activeId,
        orElse: () => profiles.first);
  }

  Future<bool> setActiveProfile(String profileId) async {
    final p = _prefs;
    if (p == null) return false;
    return await p.setString(_activeProfileIdKey, profileId);
  }

  Future<bool> saveProfile(UserProfile profile) async {
    final p = _prefs;
    if (p == null) return false;
    final profiles = getProfiles();
    final index = profiles.indexWhere((prof) => prof.id == profile.id);

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
        .map((prof) => UserProfileModel.fromEntity(prof).toJson())
        .toList();
    return await p.setString(_profilesKey, jsonEncode(jsonList));
  }

  Future<bool> deleteProfile(String profileId) async {
    final p = _prefs;
    if (p == null) return false;
    final profiles = getProfiles();
    if (profiles.length <= 1) {
      return false;
    }

    final updatedList = profiles.where((prof) => prof.id != profileId).toList();
    final jsonList = updatedList
        .map((prof) => UserProfileModel.fromEntity(prof).toJson())
        .toList();
    final res = await p.setString(_profilesKey, jsonEncode(jsonList));

    final activeId = p.getString(_activeProfileIdKey);
    if (activeId == profileId) {
      await setActiveProfile(updatedList.first.id);
    }
    return res;
  }

  void _saveProfilesSync(List<UserProfile> profiles) {
    final p = _prefs;
    if (p == null) return;
    final jsonList =
        profiles.map((prof) => UserProfileModel.fromEntity(prof).toJson()).toList();
    p.setString(_profilesKey, jsonEncode(jsonList));
  }
}
