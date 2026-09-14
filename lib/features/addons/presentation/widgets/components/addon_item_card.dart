import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../../core/presentation/primitives/aura_card.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';

import '../../../domain/entities/addon_manifest.dart';

class AddonItemCard extends StatelessWidget {
  final AddonManifest addon;
  final VoidCallback onUninstall;
  final VoidCallback? onConfigure;

  const AddonItemCard({
    super.key,
    required this.addon,
    required this.onUninstall,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final isOfficial = addon.id.contains('official') || addon.id.contains('cinemeta');

    return AuraCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon / Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                ),
                child: addon.icon != null
                    ? Image.network(
                        addon.icon!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const AuraIcon(
                          AppIcons.extension,
                          color: AppColors.accentPink,
                          size: 24,
                        ),
                      )
                    : const AuraIcon(
                        AppIcons.extension,
                        color: AppColors.accentPink,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),

              // Title & Version
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            addon.name,
                            style: context.auraText.itemTitle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOfficial) ...[
                          const SizedBox(width: 6),
                          const AuraBadge(
                            label: 'OFFICIAL',
                            backgroundColor: Color(0x1EA0E1E5),
                            borderColor: AppColors.accentPink,
                            textColor: AppColors.accentPink,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${addon.version} • ${addon.id}',
                      style: context.auraText.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description
          if (addon.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              addon.description,
              style: context.auraText.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          // Resource Badges & Action Buttons
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: addon.resources.map((res) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusSmall),
                      ),
                      child: Text(
                        res.toUpperCase(),
                        style: context.auraText.metadataPill.copyWith(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (!isOfficial)
                IconButton(
                  icon: const AuraIcon(AppIcons.delete,
                      color: AppColors.statusError, size: 20),
                  tooltip: 'Uninstall Add-on',
                  onPressed: onUninstall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
