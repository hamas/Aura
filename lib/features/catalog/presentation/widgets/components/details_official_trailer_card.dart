import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';

/// 16:9 Official Trailer Section card with interactive thumbnail and Play overlay.
class DetailsOfficialTrailerCard extends StatelessWidget {
  final MediaItem item;

  const DetailsOfficialTrailerCard({
    super.key,
    required this.item,
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

  String? _getTrailerThumbnailUrl() {
    if (item.trailerUrl == null || item.trailerUrl!.isEmpty) return null;
    final uri = Uri.tryParse(item.trailerUrl!);
    if (uri != null) {
      final key = uri.queryParameters['v'];
      if (key != null && key.isNotEmpty) {
        return 'https://img.youtube.com/vi/$key/hqdefault.jpg';
      }
    }
    // Fallback to backdrop
    return item.backdropPath != null
        ? '${ApiConstants.tmdbBackdropW1280}${item.backdropPath}'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (item.trailerUrl == null || item.trailerUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final thumbnailUrl = _getTrailerThumbnailUrl();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Official Trailer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HD',
                style: TextStyle(
                  color: AppColors.accentPink,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: AppColors.surfaceElevated,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailUrl != null)
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Center(
                          child: AuraIcon(
                            AppIcons.movie,
                            color: AppColors.textMuted,
                            size: 36,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: AuraIcon(
                          AppIcons.movie,
                          color: AppColors.textMuted,
                          size: 36,
                        ),
                      ),
                    ),

                  // Dark Scrim Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),

                  // Play Button CTA Overlay
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openExternalTrailer(context),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const AuraIcon(
                            AppIcons.play,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Watch Trailer Label
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 12,
                    child: Row(
                      children: [
                        const AuraIcon(
                          AppIcons.play,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Watch Trailer on YouTube',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
