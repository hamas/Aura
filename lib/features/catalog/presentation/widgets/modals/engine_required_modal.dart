import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';

class EngineRequiredModal extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGoToAddons;

  const EngineRequiredModal({
    super.key,
    required this.title,
    required this.message,
    required this.onGoToAddons,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onGoToAddons,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => EngineRequiredModal(
        title: title,
        message: message,
        onGoToAddons: () {
          Navigator.pop(sheetContext);
          onGoToAddons();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLarge),
        ),
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: EdgeInsets.only(
        left: AppTokens.spacingLg,
        right: AppTokens.spacingLg,
        top: AppTokens.spacingLg,
        bottom: MediaQuery.of(context).padding.bottom + AppTokens.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTokens.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha((0.4 * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: const AuraIcon(
                  AppIcons.extension,
                  color: AppColors.accentPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTokens.spacingMd),
              Expanded(
                child: Text(
                  title,
                  style: context.auraText.sectionTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTokens.spacingMd),

          Text(
            message,
            style: context.auraText.bodyOverview.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMd),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGoToAddons,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPink,
                    foregroundColor: AppColors.surfaceBackground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const AuraIcon(AppIcons.extension, size: 18),
                  label: const Text('Go to Add-ons'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
