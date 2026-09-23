import 'package:flutter/material.dart';
import 'package:aura/features/downloads/presentation/widgets/download_action_button.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

class DetailsActionButtons extends StatelessWidget {
  final MediaItem item;
  final bool isInWatchlist;
  final VoidCallback onPlayPressed;
  final VoidCallback? onTrailerPressed;
  final VoidCallback onDownloadPressed;
  final VoidCallback onPlayOfflinePressed;

  const DetailsActionButtons({
    super.key,
    required this.item,
    required this.isInWatchlist,
    required this.onPlayPressed,
    this.onTrailerPressed,
    required this.onDownloadPressed,
    required this.onPlayOfflinePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Watch Trailer Button (5% White Glassmorphic Button)
        if (onTrailerPressed != null &&
            item.trailerUrl != null &&
            item.trailerUrl!.isNotEmpty) ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            onPressed: onTrailerPressed,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Watch Trailer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],

        // Play Stream Button (Solid White Background with Black Text)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            minimumSize: const Size(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          onPressed: onPlayPressed,
          child: const Text(
            'Play',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Download Action Button wrapped in 5% white circle background (Movies only)
        if (item.type == MediaType.movie) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Center(
              child: DownloadActionButton(
                mediaId: item.id,
                mediaType: item.type,
                iconSize: 18,
                onStartDownload: onDownloadPressed,
                onPlayOffline: onPlayOfflinePressed,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
