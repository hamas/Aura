import 'dart:ui';
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
    final backdropUrl = item.backdropPath != null
        ? '${ApiConstants.tmdbImageBaseUrl}${item.backdropPath}'
        : null;

    return SliverToBoxAdapter(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: overlappingHeader != null ? 440.0 : 400.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Static TMDB Backdrop Image with Ken Burns Fallback
                if (backdropUrl != null)
                  CachedNetworkImage(
                    imageUrl: backdropUrl,
                    fit: BoxFit.cover,
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

                // 2. Bottom Seamless Scrim Gradient Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: ClipRect(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0x99FFFFFF),
                                  Color(0xFFFFFFFF),
                                ],
                                stops: [0.0, 0.45, 1.0],
                              ).createShader(bounds);
                            },
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                              child: const ColoredBox(color: Colors.black),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.85),
                                  AppColors.surfaceBackground,
                                ],
                                stops: const [0.35, 0.60, 0.82, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Overlapping Poster & Metadata Row directly inside backdrop Stack
          if (overlappingHeader != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: overlappingHeader!,
            ),
        ],
      ),
    );
  }
}
