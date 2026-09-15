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


class DetailsBackdropSliver extends StatefulWidget {
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
  State<DetailsBackdropSliver> createState() => _DetailsBackdropSliverState();
}

class _DetailsBackdropSliverState extends State<DetailsBackdropSliver> {
  bool _isMuted = true;

  @override
  Widget build(BuildContext context) {
    final backdropUrl = widget.item.backdropPath != null
        ? '${ApiConstants.tmdbImageBaseUrl}${widget.item.backdropPath}'
        : null;

    return SliverAppBar(
      expandedHeight: 340.0,
      pinned: true,
      backgroundColor: AppColors.surfaceBackground,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop Image / Trailer Thumbnail Layer
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

            // Mute / Unmute & Trailer indicator overlay
            if (widget.item.trailerUrl != null)
              Positioned(
                right: 18,
                top: 70,
                child: InkWell(
                  onTap: () => setState(() => _isMuted = !_isMuted),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuraIcon(
                          _isMuted ? AppIcons.volumeOff : AppIcons.volumeUp,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isMuted ? 'TRAILER MUTE' : 'TRAILER ON',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
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
                      child: widget.item.posterPath != null
                          ? CachedNetworkImage(
                              imageUrl:
                                  '${ApiConstants.tmdbPosterW500}${widget.item.posterPath}',
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
                        Text(
                          widget.item.title,
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
                            AuraBadge(label: widget.item.releaseYear.toString()),
                            AuraBadge(
                                label: widget.item.voteAverage.toStringAsFixed(1)),
                            AuraBadge(
                              label: widget.item.type == MediaType.movie
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
            widget.isInWatchlist ? AppIcons.bookmark : AppIcons.bookmark,
            color:
                widget.isInWatchlist ? AppColors.accentPink : AppColors.textPrimary,
          ),
          onPressed: widget.onToggleWatchlist,
        ),
        IconButton(
          icon: const AuraIcon(AppIcons.share, color: AppColors.textPrimary),
          onPressed: widget.onShare,
        ),
      ],
    );
  }
}
