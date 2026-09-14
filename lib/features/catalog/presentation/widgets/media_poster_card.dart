import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/media_item.dart';

/// 2:3 Theatrical Media Poster Card with interactive focus/hover scale and rating badges.
class MediaPosterCard extends StatefulWidget {
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
  State<MediaPosterCard> createState() => _MediaPosterCardState();
}

class _MediaPosterCardState extends State<MediaPosterCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  bool get _isActive => _isHovered || _isFocused;

  @override
  Widget build(BuildContext context) {
    final height = widget.width / AppTokens.posterAspectRatio;

    return FocusableActionDetector(
      onShowHoverHighlight: (hovered) {
        if (_isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isActive ? AppTokens.focusScaleFactor : 1.0,
          duration: AppTokens.focusAnimationDuration,
          curve: AppTokens.focusAnimationCurve,
          child: SizedBox(
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2:3 Poster Frame
                Container(
                  width: widget.width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: AppTokens.borderRadiusSmall,
                    border: Border.all(
                      color: _isActive
                          ? AppColors.accentPink
                          : const Color(0xFF2A2A2A),
                      width: _isActive ? AppTokens.focusBorderWidth : 1.0,
                    ),
                    boxShadow: _isActive
                        ? [
                            BoxShadow(
                              color: AppColors.accentPink.withAlpha(
                                (0.35 * 255).round(),
                              ),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      _isActive
                          ? AppTokens.radiusSmall - 1
                          : AppTokens.radiusSmall,
                    ),
                    child: Container(
                      color: AppColors.surfaceCard,
                      child: widget.item.posterPath != null
                          ? CachedNetworkImage(
                              imageUrl: widget.item.fullPosterUrl,
                              fit: BoxFit.cover,
                              width: widget.width,
                              height: height,
                              memCacheWidth: (widget.width * 2).round(),
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
                  ),
                ),

                if (widget.showTitle) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (widget.showRating) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warningAccent,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.item.formattedRating,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.item.releaseYear.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.item.releaseYear,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
