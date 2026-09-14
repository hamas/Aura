import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
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
      height: height,
      child: AuraCard(
        width: width,
        height: height,
        onTap: onTap,
        borderRadius: AppTokens.borderRadiusCard,
        child: ClipRRect(
          borderRadius: AppTokens.borderRadiusCard,
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
                      child: AuraIcon(
                        AppIcons.movie,
                        color: AppColors.textMuted,
                        size: 28,
                      ),
                    ),
                  ),
                )
              : Container(
                  color: AppColors.surfaceElevated,
                  child: const Center(
                    child: AuraIcon(
                      AppIcons.movie,
                      color: AppColors.textMuted,
                      size: 28,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
