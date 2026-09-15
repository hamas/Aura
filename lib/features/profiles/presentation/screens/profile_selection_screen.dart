import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/presentation/primitives/aura_scaffold.dart';
import '../../data/services/profile_manager.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/components/profile_card.dart';
import '../widgets/components/pin_entry_dialog.dart';

import '../../../../core/presentation/primitives/aura_adaptive_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/components/profile_editor_modal.dart';

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

  Future<void> _loadProfiles() async {
    final manager = widget.profileManager ?? await ProfileManager.getInstance();
    setState(() {
      _profiles = manager.getProfiles();
      _activeProfile = manager.getActiveProfile();
    });
  }

  Future<void> _openManageProfiles() async {
    final authState = context.read<AuthBloc>().state;
    if (!authState.isGoogleAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile creation and management requires signing in with your Google Account in Settings.'),
          backgroundColor: AppColors.surfaceCard,
        ),
      );
      return;
    }
    final manager = widget.profileManager ?? await ProfileManager.getInstance();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileEditorModal(
        profileManager: manager,
        onSaved: () {
          _loadProfiles();
        },
      ),
    );
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
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingLg,
                vertical: 80.0,
              ),
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.spacingXl),
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
                  const SizedBox(height: 36),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () => _openManageProfiles(),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
                    label: const Text('Manage Profiles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'Profiles',
              opacity: 1.0,
              actions: [
                TextButton.icon(
                  onPressed: () => _openManageProfiles(),
                  icon: const Icon(Icons.edit, size: 14, color: Colors.white70),
                  label: const Text(
                    'Manage',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
