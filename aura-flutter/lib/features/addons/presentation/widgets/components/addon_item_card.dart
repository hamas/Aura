import 'package:flutter/material.dart';
import '../../../../../core/presentation/primitives/aura_icon.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
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
    final isOfficial =
        addon.id.contains('official') || addon.id.contains('cinemeta');

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
            children: [
              // Icon / Logo
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: addon.icon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          addon.icon!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const AuraIcon(
                            AppIcons.extension,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    : const AuraIcon(
                        AppIcons.extension,
                        color: Colors.white,
                        size: 20,
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
                            style: context.auraText.bodyOverview.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOfficial) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0x1AFFFFFF)),
                            ),
                            child: Text(
                              'OFFICIAL',
                              style: context.auraText.caption.copyWith(
                                color: Colors.white70,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${addon.version} • ${addon.id}',
                      style: context.auraText.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
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
                color: AppColors.textMuted,
                fontSize: 12.0,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        res.toUpperCase(),
                        style: context.auraText.metadataPill.copyWith(
                          fontSize: 9.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (!isOfficial)
                IconButton(
                  icon: const AuraIcon(AppIcons.delete,
                      color: AppColors.statusError, size: 18),
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
