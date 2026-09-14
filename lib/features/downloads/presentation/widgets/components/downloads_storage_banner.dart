import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../bloc/downloads_state.dart';

class DownloadsStorageBanner extends StatelessWidget {
  final DownloadsState state;

  const DownloadsStorageBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Storage Bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingMd,
            vertical: AppTokens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: AppTokens.borderRadiusSmall,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const AuraIcon(
                AppIcons.folderSpecial,
                color: AppColors.accentPink,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Private Vault Storage',
                      style: context.auraText.bodyOverview.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.completedTasks.length} offline titles • ${state.formattedTotalStorage}',
                      style: context.auraText.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const AuraBadge(
                label: 'SANDBOXED',
                backgroundColor: Color(0x1EB877FF),
                borderColor: AppColors.accentPink,
                textColor: AppColors.accentPink,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Smart Downloads Status Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppTokens.borderRadiusSmall,
            border: Border.all(
              color: AppColors.accentPink.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Row(
            children: [
              const AuraIcon(
                AppIcons.autoAwesome,
                color: AppColors.accentPink,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Watched episodes deleted • Next 2 episodes queued on Wi-Fi',
                  style: context.auraText.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const AuraBadge(
                label: 'COMMUTER MODE',
                backgroundColor: Color(0x1EA0E1E5),
                borderColor: AppColors.accentPink,
                textColor: AppColors.accentPink,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DownloadsEmptyState extends StatelessWidget {
  const DownloadsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTokens.spacingLg),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const AuraIcon(
                AppIcons.downloadForOffline,
                size: 56,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Offline Downloads',
              style: context.auraText.sectionTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download movies and episodes to watch seamlessly without an internet connection.',
              textAlign: TextAlign.center,
              style: context.auraText.bodyOverview.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
