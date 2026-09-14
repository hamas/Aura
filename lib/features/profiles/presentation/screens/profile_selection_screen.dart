import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/primitives/aura_scaffold.dart';
import '../../data/services/profile_manager.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/components/profile_card.dart';
import '../widgets/components/pin_entry_dialog.dart';

class ProfileSelectionScreen extends StatefulWidget {
  final ProfileManager? profileManager;
  final VoidCallback? onProfileSelected;

  const ProfileSelectionScreen({
    super.key,
    this.profileManager,
    this.onProfileSelected,
  });

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  List<UserProfile> _profiles = [];
  UserProfile? _activeProfile;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    if (widget.profileManager != null) {
      setState(() {
        _profiles = widget.profileManager!.getProfiles();
        _activeProfile = widget.profileManager!.getActiveProfile();
      });
    }
  }

  void _selectProfile(UserProfile profile) {
    if (profile.hasPin) {
      showDialog<void>(
        context: context,
        builder: (_) => PinEntryDialog(
          targetProfile: profile,
          onPinSubmitted: (pin) {
            _activateProfile(profile);
          },
        ),
      );
    } else {
      _activateProfile(profile);
    }
  }

  void _activateProfile(UserProfile profile) {
    if (widget.profileManager != null) {
      widget.profileManager!.setActiveProfile(profile.id);
    }
    setState(() {
      _activeProfile = profile;
    });
    if (widget.onProfileSelected != null) {
      widget.onProfileSelected!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Who's watching?",
                style: context.auraText.displayHero.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                'Select a profile to customize recommendations & history',
                style: context.auraText.caption
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppTokens.spacingXl),
              if (_profiles.isEmpty)
                ProfileCard(
                  profile: UserProfile(
                    id: 'p1',
                    name: 'Primary Account',
                    avatarPath: '',
                    createdAt: DateTime.now(),
                  ),
                  isActive: true,
                  onTap: () {
                    if (widget.onProfileSelected != null) {
                      widget.onProfileSelected!();
                    }
                  },
                )
              else
                Wrap(
                  spacing: AppTokens.spacingLg,
                  runSpacing: AppTokens.spacingLg,
                  alignment: WrapAlignment.center,
                  children: [
                    ..._profiles.map((profile) {
                      final isActive = profile.id == _activeProfile?.id;
                      return ProfileCard(
                        profile: profile,
                        isActive: isActive,
                        onTap: () => _selectProfile(profile),
                      );
                    }),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
