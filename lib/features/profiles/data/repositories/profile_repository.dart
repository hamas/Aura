import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../services/profile_manager.dart';

abstract class ProfileRepository {
  Future<List<UserProfile>> getProfiles();
  Future<UserProfile?> getActiveProfile();
  Future<void> setActiveProfile(String profileId);
  Future<void> saveProfile(UserProfile profile);
  Future<void> deleteProfile(String profileId);
}

class LocalProfileRepository implements ProfileRepository {
  final ProfileManager _manager;

  LocalProfileRepository(SharedPreferences prefs)
      : _manager = ProfileManager(prefs);

  @override
  Future<List<UserProfile>> getProfiles() async {
    return _manager.getProfiles();
  }

  @override
  Future<UserProfile?> getActiveProfile() async {
    return _manager.getActiveProfile();
  }

  @override
  Future<void> setActiveProfile(String profileId) async {
    await _manager.setActiveProfile(profileId);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _manager.saveProfile(profile);
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    await _manager.deleteProfile(profileId);
  }
}
