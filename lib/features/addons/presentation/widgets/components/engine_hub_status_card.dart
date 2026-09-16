import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../../core/presentation/primitives/aura_card.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';

enum EngineStatus {
  notInstalled,
  downloading,
  installed,
  error,
}

class EngineHubStatusCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final EngineStatus status;
  final String? errorMessage;
  final VoidCallback onInstallOrUpdate;
  final VoidCallback? onUninstall;
  final ValueChanged<bool>? onToggleActive;
  final bool isActive;

  const EngineHubStatusCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.onInstallOrUpdate,
    this.errorMessage,
    this.onUninstall,
    this.onToggleActive,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isInstalled = status == EngineStatus.installed;
    final isDownloading = status == EngineStatus.downloading;
    final hasError = status == EngineStatus.error;

    return AuraCard(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Engine Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isInstalled
                      ? AppColors.accentPink.withAlpha((0.15 * 255).round())
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(
                    color: isInstalled
                        ? AppColors.accentPink.withAlpha((0.3 * 255).round())
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Center(
                  child: AuraIcon(
                    icon,
                    color: isInstalled ? AppColors.accentPink : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMd),

              // Title, Status Pill & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: context.auraText.itemTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        _buildStatusBadge(context),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasError && errorMessage != null) ...[
            const SizedBox(height: AppTokens.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusError.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              ),
              child: Row(
                children: [
                  const AuraIcon(AppIcons.errorOutline,
                      color: AppColors.statusError, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: context.auraText.caption
                          .copyWith(color: AppColors.statusError, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTokens.spacingMd),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isInstalled && onToggleActive != null)
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 40,
                      child: Switch(
                        value: isActive,
                        onChanged: onToggleActive,
                        activeThumbColor: AppColors.accentPink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'Engine Active' : 'Engine Disabled',
                      style: context.auraText.caption.copyWith(
                        color: isActive ? AppColors.accentPink : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInstalled && onUninstall != null) ...[
                    TextButton.icon(
                      onPressed: onUninstall,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.statusError,
                      ),
                      icon: const AuraIcon(AppIcons.delete,
                          color: AppColors.statusError, size: 16),
                      label: const Text('Uninstall'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: isDownloading ? null : onInstallOrUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isInstalled ? AppColors.surfaceElevated : AppColors.accentPink,
                      foregroundColor:
                          isInstalled ? AppColors.textPrimary : AppColors.surfaceBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Text(isInstalled ? 'Update' : 'Install Engine'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    switch (status) {
      case EngineStatus.installed:
        return const AuraBadge(
          label: 'INSTALLED',
          backgroundColor: Color(0x1E4CAF50),
          borderColor: AppColors.statusSuccess,
          textColor: AppColors.statusSuccess,
        );
      case EngineStatus.downloading:
        return const AuraBadge(
          label: 'INSTALLING...',
          backgroundColor: Color(0x1EFFC107),
          borderColor: AppColors.statusWarning,
          textColor: AppColors.statusWarning,
        );
      case EngineStatus.error:
        return const AuraBadge(
          label: 'ERROR',
          backgroundColor: Color(0x1EF44336),
          borderColor: AppColors.statusError,
          textColor: AppColors.statusError,
        );
      case EngineStatus.notInstalled:
        return const AuraBadge(
          label: 'NOT INSTALLED',
          backgroundColor: Color(0x1E9E9E9E),
          borderColor: AppColors.textMuted,
          textColor: AppColors.textMuted,
        );
    }
  }
}
