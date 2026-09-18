import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
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

  Future<void> _openExternalTrailer(BuildContext context) async {
    final youtubeKey = item.trailerUrl;
    if (youtubeKey != null && youtubeKey.isNotEmpty) {
      final String rawUrl = youtubeKey.startsWith('http')
          ? youtubeKey
          : 'https://www.youtube.com/watch?v=$youtubeKey';
      final uri = Uri.parse(rawUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text('Official trailer link unavailable for this title.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backdropUrl = item.backdropPath != null
        ? '${ApiConstants.tmdbImageBaseUrl}${item.backdropPath}'
        : null;

    final hasTrailer = item.trailerUrl != null && item.trailerUrl!.isNotEmpty;

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

                // 2. Play Trailer Button Overlay
                if (hasTrailer)
                  Center(
                    child: GestureDetector(
                      onTap: () => _openExternalTrailer(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const AuraIcon(
                          AppIcons.play,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // 3. Bottom Seamless Scrim Gradient Overlay
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
