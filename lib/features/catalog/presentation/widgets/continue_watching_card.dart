import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/domain/entities/library_item.dart';

/// 16:9 Netflix-style Continue Watching Card built on [AuraCard] and [AuraBadge].
class ContinueWatchingCard extends StatelessWidget {
  final LibraryItem item;
  final VoidCallback? onTap;
  final double width;

  const ContinueWatchingCard({
    super.key,
    required this.item,
    this.onTap,
    this.width = AppTokens.continueWatchingWidth,
  });

  @override
  Widget build(BuildContext context) {
    final progress = item.progress;
    final percent = (progress?.percentage ?? 0.0).clamp(0.0, 1.0);
    final isTv = item.type == 'series' || item.type == 'tv';

    final mediaUrl = item.backdropPath != null
        ? (item.backdropPath!.startsWith('http')
            ? item.backdropPath!
            : 'https://image.tmdb.org/t/p/w780${item.backdropPath}')
        : (item.posterPath != null
            ? (item.posterPath!.startsWith('http')
                ? item.posterPath!
                : 'https://image.tmdb.org/t/p/w500${item.posterPath}')
            : null);

    final height = width / AppTokens.backdropAspectRatio;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 16:9 Surface Card
          AuraCard(
            width: width,
            height: height,
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail Image
                mediaUrl != null
                    ? CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                        memCacheWidth: (width * 2).round(),
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceElevated,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceElevated,
                          child: const Center(
                            child: AuraIcon(
                              AppIcons.clips,
                              color: AppColors.textMuted,
                              size: 32,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: AuraIcon(
                            AppIcons.clips,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                        ),
                      ),

                // Subtle dark overlay
                Container(
                  color: Colors.black.withAlpha((0.25 * 255).round()),
                ),

                // Center Play Button Overlay
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.75 * 255).round()),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha((0.3 * 255).round()),
                        width: 1.5,
                      ),
                    ),
                    child: const AuraIcon(
                      AppIcons.play,
                      color: Colors.white,
                      fill: 1.0,
                      size: 22,
                    ),
                  ),
                ),

                // Episode Indicator Badge (Top Right)
                if (isTv &&
                    progress?.seasonNumber != null &&
                    progress?.episodeNumber != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: AuraBadge.episode(
                      progress!.seasonNumber!,
                      progress.episodeNumber!,
                    ),
                  ),

                // Bottom Linear Progress Track
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTokens.radiusSmall),
                      bottomRight: Radius.circular(AppTokens.radiusSmall),
                    ),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentPink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          // Title and Remaining Meta
          Text(
            item.title,
            style: AppTypography.itemTitle.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (progress != null && progress.remainingMinutes > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${progress.remainingMinutes}m remaining',
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
