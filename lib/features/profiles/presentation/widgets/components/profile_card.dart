import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/presentation/primitives/aura_card.dart';
import '../../../../../core/presentation/primitives/aura_badge.dart';
import '../../../domain/entities/user_profile.dart';

class ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.accentPink : AppColors.borderSubtle,
              width: 2,
            ),
          ),
          child: AuraCard(
            onTap: onTap,
            borderRadius: BorderRadius.circular(50),
            padding: const EdgeInsets.all(AppTokens.spacingSm),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: profile.isKids
                    ? Colors.orange.withValues(alpha: 0.2)
                    : AppColors.surfaceElevated,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    profile.isKids ? Icons.child_care : Icons.person_rounded,
                    size: 48,
                    color: profile.isKids
                        ? Colors.orangeAccent
                        : AppColors.accentPink,
                  ),
                  if (profile.hasPin)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: AppColors.accentPink,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profile.name,
              style: context.auraText.itemTitle.copyWith(
                color: isActive ? AppColors.accentPink : AppColors.textPrimary,
              ),
            ),
            if (profile.isKids) ...[
              const SizedBox(width: AppTokens.spacingXs),
              const AuraBadge(
                  label: 'KIDS', backgroundColor: Colors.orangeAccent),
            ],
          ],
        ),
      ],
    );
  }
}
