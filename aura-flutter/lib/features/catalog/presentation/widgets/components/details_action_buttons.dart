import 'package:flutter/material.dart';
import 'package:aura/features/downloads/presentation/widgets/download_action_button.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

class DetailsActionButtons extends StatelessWidget {
  final MediaItem item;
  final bool isInWatchlist;
  final VoidCallback onPlayPressed;
  final VoidCallback? onStreamsPressed;
  final VoidCallback? onTrailerPressed;
  final VoidCallback onDownloadPressed;
  final VoidCallback onPlayOfflinePressed;
  final bool isResolving;

  const DetailsActionButtons({
    super.key,
    required this.item,
    required this.isInWatchlist,
    required this.onPlayPressed,
    this.onStreamsPressed,
    this.onTrailerPressed,
    required this.onDownloadPressed,
    required this.onPlayOfflinePressed,
    this.isResolving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Instant Play Stream Button (Solid White Background with Black Text)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          onPressed: isResolving ? null : onPlayPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isResolving) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                const SizedBox(width: 4),
              ],
              Text(
                isResolving ? 'Starting...' : 'Play',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Streams / Quality Selector Button (Glassmorphic)
        if (onStreamsPressed != null) ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            onPressed: onStreamsPressed,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Streams',
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

        // Watch Trailer Button (5% White Glassmorphic Button)
        if (onTrailerPressed != null &&
            item.trailerUrl != null &&
            item.trailerUrl!.isNotEmpty) ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            onPressed: onTrailerPressed,
            child: const Text(
              'Trailer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // Download Action Button wrapped in 5% white circle background (Movies only)
        if (item.type == MediaType.movie) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Center(
              child: DownloadActionButton(
                mediaId: item.id,
                mediaType: item.type,
                iconSize: 20,
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
