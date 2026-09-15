import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:aura/core/constants/api_constants.dart';
import 'package:aura/core/presentation/primitives/aura_icon.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
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

            // Mute / Unmute Trailer Button (Icon-Only, Bottom Right)
            if (widget.item.trailerUrl != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _isMuted = !_isMuted),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: AuraIcon(
                        _isMuted ? AppIcons.volumeOff : AppIcons.volumeUp,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
