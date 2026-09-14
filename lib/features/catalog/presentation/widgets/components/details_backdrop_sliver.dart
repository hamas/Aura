import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/aura_badge.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

class DetailsBackdropSliver extends StatelessWidget {
  final MediaItem item;
  final bool isInWatchlist;
  final VoidCallback onToggleWatchlist;
  final VoidCallback onShare;

  const DetailsBackdropSliver({
    super.key,
    required this.item,
    required this.isInWatchlist,
    required this.onToggleWatchlist,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final backdropUrl = item.backdropPath != null
        ? '${ApiConstants.tmdbImageBaseUrl}${item.backdropPath}'
        : null;

    return SliverAppBar(
      expandedHeight: 320.0,
      pinned: true,
      backgroundColor: AppColors.surfaceBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdropUrl != null)
              CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceCard),
              )
            else
              Container(color: AppColors.surfaceCard),

            // Top gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),

            // Bottom cinematic gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.surfaceBackground,
                  ],
                  stops: [0.3, 1.0],
                ),
              ),
            ),

            // Floating Poster & Info Pill Overlay at base of backdrop
            Positioned(
              left: 18,
              right: 18,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 95,
                    height: 142,
                    decoration: BoxDecoration(
                      borderRadius: AppTokens.borderRadiusSmall,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppTokens.borderRadiusSmall,
                      child: item.posterPath != null
                          ? CachedNetworkImage(
                              imageUrl:
                                  '${ApiConstants.tmdbPosterW500}${item.posterPath}',
                              fit: BoxFit.cover,
                            )
                          : Container(color: AppColors.surfaceCard),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.logoUrl != null && item.logoUrl!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: item.logoUrl!,
                            height: 48.0,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorWidget: (_, __, ___) => Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.auraText.displayHero.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.auraText.displayHero.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppTokens.spacingSm,
                          runSpacing: AppTokens.spacingXs,
                          children: [
                            AuraBadge(label: item.releaseYear.toString()),
                            AuraBadge(
                                label: item.voteAverage.toStringAsFixed(1)),
                            AuraBadge(
                              label: item.type == MediaType.movie
                                  ? 'MOVIE'
                                  : 'SERIES',
                              backgroundColor:
                                  AppColors.accentPink.withValues(alpha: 0.2),
                              textColor: AppColors.accentPink,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: AuraIcon(
            isInWatchlist ? AppIcons.bookmark : AppIcons.bookmark,
            color: isInWatchlist ? AppColors.accentPink : AppColors.textPrimary,
          ),
          onPressed: onToggleWatchlist,
        ),
        IconButton(
          icon: const AuraIcon(AppIcons.share, color: AppColors.textPrimary),
          onPressed: onShare,
        ),
      ],
    );
  }
}
