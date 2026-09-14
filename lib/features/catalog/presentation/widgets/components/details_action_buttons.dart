import 'package:flutter/material.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/features/downloads/presentation/widgets/download_action_button.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

class DetailsActionButtons extends StatelessWidget {
  final MediaItem item;
  final bool isInWatchlist;
  final VoidCallback onPlayPressed;
  final VoidCallback onDownloadPressed;
  final VoidCallback onPlayOfflinePressed;

  const DetailsActionButtons({
    super.key,
    required this.item,
    required this.isInWatchlist,
    required this.onPlayPressed,
    required this.onDownloadPressed,
    required this.onPlayOfflinePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Play Stream Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPink,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.borderRadiusSmall,
              ),
            ),
            onPressed: onPlayPressed,
            icon: const AuraIcon(
              AppIcons.play,
              color: Colors.black,
              size: 22,
            ),
            label: Text(
              item.type == MediaType.movie ? 'Play Movie' : 'Start Watching',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Download Action Button (Movies Only)
        if (item.type == MediaType.movie)
          DownloadActionButton(
            mediaId: item.id,
            mediaType: item.type,
            iconSize: 22,
            onStartDownload: onDownloadPressed,
            onPlayOffline: onPlayOfflinePressed,
          ),
      ],
    );
  }
}
