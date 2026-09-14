import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../core/presentation/primitives/aura_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/media_item.dart';

/// 2:3 Theatrical Media Poster Card built on global [AuraCard] and [AuraBadge] primitives.
class MediaPosterCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onTap;
  final double width;
  final bool showRating;
  final bool showTitle;

  const MediaPosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.width = AppTokens.posterWidthMobile,
    this.showRating = true,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = width / AppTokens.posterAspectRatio;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2:3 Poster Surface wrapped in AuraCard
          AuraCard(
            width: width,
            height: height,
            onTap: onTap,
            child: item.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: item.fullPosterUrl,
                    fit: BoxFit.cover,
                    width: width,
                    height: height,
                    memCacheWidth: (width * 2).round(),
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentPink,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: Icon(
                          Icons.movie_outlined,
                          color: AppColors.textMuted,
                          size: 28,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        color: AppColors.textMuted,
                        size: 28,
                      ),
                    ),
                  ),
          ),

          if (showTitle) ...[
            const SizedBox(height: 6),
            Text(
              item.title,
              style: AppTypography.itemTitle.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (showRating) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                AuraBadge.rating(item.formattedRating),
                if (item.releaseYear.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    item.releaseYear,
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
