import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/presentation/primitives/aura_card.dart';
import '../../../../../core/presentation/primitives/aura_badge.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../data/services/profile_manager.dart';

class ProfileSwitcherSheet extends StatelessWidget {
  final ProfileManager profileManager;
  final VoidCallback onProfileSwitched;
  final VoidCallback onManageProfiles;

  const ProfileSwitcherSheet({
    super.key,
    required this.profileManager,
    required this.onProfileSwitched,
    required this.onManageProfiles,
  });

  @override
  Widget build(BuildContext context) {
    final profiles = profileManager.getProfiles();
    final activeProfile = profileManager.getActiveProfile();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusSmall),
        ),
      ),
      padding: const EdgeInsets.all(AppTokens.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Switch Profile',
                style: context.auraText.sectionTitle
                    .copyWith(color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingMd),
          ...profiles.map((UserProfile profile) {
            final isActive = profile.id == activeProfile?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
              child: AuraCard(
                onTap: () async {
                  await profileManager.setActiveProfile(profile.id);
                  onProfileSwitched();
                  if (context.mounted) Navigator.of(context).pop();
                },
                padding: const EdgeInsets.all(AppTokens.spacingMd),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: profile.isKids
                          ? Colors.orangeAccent
                          : AppColors.accentPink,
                      child: Icon(
                        profile.isKids ? Icons.child_care : Icons.person,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: context.auraText.itemTitle.copyWith(
                              color: isActive
                                  ? AppColors.accentPink
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (profile.isKids)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: AuraBadge(
                                label: 'KIDS',
                                backgroundColor: Colors.orangeAccent,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isActive)
                      const Icon(Icons.check_circle,
                          color: AppColors.accentPink),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppTokens.spacingMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onManageProfiles();
              },
              icon: const Icon(Icons.settings, color: AppColors.textSecondary),
              label: Text(
                'Manage Profiles',
                style: context.auraText.itemTitle
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
