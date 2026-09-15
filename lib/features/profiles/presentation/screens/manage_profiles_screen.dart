import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../core/presentation/primitives/aura_scaffold.dart';
import '../../../../core/presentation/primitives/aura_adaptive_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/services/profile_manager.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/components/profile_editor_modal.dart';
import '../widgets/components/profile_avatar.dart';

class ManageProfilesScreen extends StatefulWidget {
  final ProfileManager profileManager;
  final VoidCallback? onProfilesUpdated;

  const ManageProfilesScreen({
    super.key,
    required this.profileManager,
    this.onProfilesUpdated,
  });

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  List<UserProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _profiles = widget.profileManager.getProfiles();
    });
    widget.onProfilesUpdated?.call();
  }

  void _openProfileEditor([UserProfile? profile]) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileEditorModal(
        initialProfile: profile,
        profileManager: widget.profileManager,
        onSaved: () {
          _loadProfiles();
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final canAddMore = _profiles.length < ProfileManager.maxProfiles;

    return AuraScaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Manage Profiles',
                    style: context.auraText.displayHero.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: Text(
                      '${_profiles.length} of ${ProfileManager.maxProfiles} slots used',
                      style: context.auraText.caption.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Profiles Grid
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      ..._profiles.map((profile) => _buildProfileItem(profile)),

                      // Add Profile Slot
                      if (canAddMore) _buildAddProfileSlot(),
                    ],
                  ),

                  if (!canAddMore) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Maximum ${ProfileManager.maxProfiles} profiles reached',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Profile Slot Status Banner
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x12FFFFFF)),
                      ),
                      child: Row(
                        children: [
                          const AuraIcon(AppIcons.infoOutline, color: Colors.white54, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Profiles allow each household member to have their own personalized watch history, watchlist, and content ratings.',
                              style: context.auraText.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Adaptive App Bar with "Done" Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'Manage Profiles',
              opacity: 1.0,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildProfileItem(UserProfile profile) {
    return GestureDetector(
      onTap: () => _openProfileEditor(profile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileAvatar(
            profile: profile,
            size: 90.0,
            onTap: () => _openProfileEditor(profile),
          ),
          const SizedBox(height: 10),
          Text(
            profile.name,
            style: context.auraText.bodyOverview.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProfileSlot() {
    return GestureDetector(
      onTap: () => _openProfileEditor(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: Colors.white38,
                width: 1.5,
              ),
            ),
            child: const Center(
              child: AuraIcon(
                AppIcons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add Profile',
            style: context.auraText.caption.copyWith(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
