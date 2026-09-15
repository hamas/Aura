import 'package:flutter/material.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
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
        // Play Stream Button (Compact / Small)
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPink,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          onPressed: onPlayPressed,
          icon: const AuraIcon(
            AppIcons.play,
            color: Colors.black,
            size: 16,
          ),
          label: Text(
            item.type == MediaType.movie ? 'Play' : 'Watch',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Download Action Button (Inline, directly after button)
        DownloadActionButton(
          mediaId: item.id,
          mediaType: item.type,
          iconSize: 20,
          onStartDownload: onDownloadPressed,
          onPlayOffline: onPlayOfflinePressed,
        ),
      ],
    );
  }
}
