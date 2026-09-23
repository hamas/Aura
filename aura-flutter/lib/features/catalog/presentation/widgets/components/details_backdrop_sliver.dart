import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/presentation/widgets/components/ambient_backdrop_fallback.dart';

class DetailsBackdropSliver extends StatelessWidget {
  final MediaItem item;
  final bool isInWatchlist;
  final VoidCallback onToggleWatchlist;
  final VoidCallback onShare;
  final Widget? overlappingHeader;

  const DetailsBackdropSliver({
    super.key,
    required this.item,
    required this.isInWatchlist,
    required this.onToggleWatchlist,
    required this.onShare,
    this.overlappingHeader,
  });

  @override
  Widget build(BuildContext context) {
    final heroHeight = MediaQuery.of(context).size.height * 0.70;

    final posterUrl = item.posterPath != null
        ? '${ApiConstants.tmdbPosterW500}${item.posterPath}'
        : null;
    final backdropUrl = item.backdropPath != null
        ? '${ApiConstants.tmdbImageBaseUrl}${item.backdropPath}'
        : null;

    final heroImageUrl = backdropUrl ?? posterUrl;

    return SliverToBoxAdapter(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Static TMDB Poster Image as Hero Background
                if (heroImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: heroImageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorWidget: (_, __, ___) => AmbientBackdropFallback(
                      backdropUrl: null,
                      title: item.title,
                    ),
                  )
                else
                  AmbientBackdropFallback(
                    backdropUrl: null,
                    title: item.title,
                  ),

                // 2. Deep Scrim Gradient Overlay for Text Legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.90),
                          AppColors.surfaceBackground,
                        ],
                        stops: const [0.0, 0.25, 0.55, 0.85, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Overlapping Title & Metadata Row directly inside hero Stack
          if (overlappingHeader != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: overlappingHeader!,
            ),
        ],
      ),
    );
  }
}
