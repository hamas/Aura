import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x1AFFFFFF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Engine Icon Container matching Settings menu items
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: AuraIcon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),

              // Title, Status & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: context.auraText.bodyOverview.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(context),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12.0,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasError && errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusError.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
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

          const SizedBox(height: 14),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isInstalled && onToggleActive != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x1AFFFFFF),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: isActive,
                          onChanged: onToggleActive,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.white38,
                          inactiveThumbColor: Colors.white30,
                          inactiveTrackColor: Colors.white10,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Active' : 'Disabled',
                        style: context.auraText.caption.copyWith(
                          color: isActive ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInstalled && onUninstall != null) ...[
                    TextButton(
                      onPressed: onUninstall,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.statusError,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        'Uninstall',
                        style: context.auraText.caption.copyWith(
                          color: AppColors.statusError,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: isDownloading ? null : onInstallOrUpdate,
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isInstalled
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0x22FFFFFF),
                        ),
                      ),
                      child: isDownloading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isInstalled ? 'Update' : 'Install Engine',
                              style: context.auraText.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.0,
                              ),
                            ),
                    ),
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
