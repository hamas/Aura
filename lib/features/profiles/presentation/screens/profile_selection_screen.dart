import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/aura_theme.dart';
import '../../data/services/profile_manager.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/aura_pin_modal.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final VoidCallback onProfileSelected;

  const ProfileSelectionScreen({
    super.key,
    required this.onProfileSelected,
  });

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  ProfileManager? _manager;
  List<UserProfile> _profiles = [];
  UserProfile? _activeProfile;
  bool _isManaging = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    _manager = ProfileManager(prefs);
    setState(() {
      _profiles = _manager!.getProfiles();
      _activeProfile = _manager!.getActiveProfile();
    });
  }

  Future<void> _selectProfile(UserProfile profile) async {
    if (_activeProfile?.isKids == true && !profile.isKids) {
      // Prompt PIN when switching out of Kids profile into adult profile
      if (profile.hasPin) {
        final verified = await AuraPinModal.show(
          context,
          onVerifyPin: (pin) => profile.verifyPin(pin),
        );
        if (verified != true) return;
      }
    }

    await _manager?.setActiveProfile(profile.id);
    widget.onProfileSelected();
  }

  Future<void> _addProfile() async {
    if (_profiles.length >= ProfileManager.maxProfiles) return;
    final newProfile = UserProfile(
      id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
      name: 'User ${_profiles.length + 1}',
      avatarPath: 'assets/avatars/avatar_${_profiles.length + 1}.png',
      isKids: false,
      createdAt: DateTime.now(),
    );
    await _manager?.saveProfile(newProfile);
    await _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Who's watching?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 36),

              // Profiles Grid
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  ..._profiles.map((profile) {
                    final isActive = profile.id == _activeProfile?.id;
                    return InkWell(
                      onTap: () => _selectProfile(profile),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primaryAccent
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryAccent
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: CircleAvatar(
                              backgroundColor: AppColors.surfaceCard,
                              child: Text(
                                profile.name.isNotEmpty
                                    ? profile.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              if (profile.isKids) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'KIDS',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add Profile Slot
                  if (_profiles.length < ProfileManager.maxProfiles)
                    InkWell(
                      onTap: _addProfile,
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceCard,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.textMuted,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Add Profile',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.surfaceCard),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  setState(() => _isManaging = !_isManaging);
                },
                child: Text(_isManaging ? 'Done' : 'Manage Profiles'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
