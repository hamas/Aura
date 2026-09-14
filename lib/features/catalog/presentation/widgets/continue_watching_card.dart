import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../library/domain/entities/library_item.dart';

/// 16:9 Netflix-style Continue Watching Card with play overlay and purple progress indicator.
class ContinueWatchingCard extends StatefulWidget {
  final LibraryItem item;
  final VoidCallback? onTap;
  final double width;

  const ContinueWatchingCard({
    super.key,
    required this.item,
    this.onTap,
    this.width = AppTokens.continueWatchingWidth,
  });

  @override
  State<ContinueWatchingCard> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<ContinueWatchingCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  bool get _isActive => _isHovered || _isFocused;

  @override
  Widget build(BuildContext context) {
    final progress = widget.item.progress;
    final percent = (progress?.percentage ?? 0.0).clamp(0.0, 1.0);
    final isTv = widget.item.type == 'series' || widget.item.type == 'tv';

    final mediaUrl = widget.item.backdropPath != null
        ? (widget.item.backdropPath!.startsWith('http')
            ? widget.item.backdropPath!
            : 'https://image.tmdb.org/t/p/w780${widget.item.backdropPath}')
        : (widget.item.posterPath != null
            ? (widget.item.posterPath!.startsWith('http')
                ? widget.item.posterPath!
                : 'https://image.tmdb.org/t/p/w500${widget.item.posterPath}')
            : null);

    final height = widget.width / AppTokens.backdropAspectRatio;

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
                // 16:9 Thumbnail Stack
                Container(
                  width: widget.width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: AppTokens.borderRadiusSmall,
                    border: Border.all(
                      color: _isActive
                          ? AppColors.accentPink
                          : const Color(0xFF2E2E2E),
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail Image
                        mediaUrl != null
                            ? CachedNetworkImage(
                                imageUrl: mediaUrl,
                                fit: BoxFit.cover,
                                width: widget.width,
                                height: height,
                                memCacheWidth: (widget.width * 2).round(),
                                placeholder: (_, __) => Container(
                                  color: AppColors.surfaceElevated,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surfaceElevated,
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      color: AppColors.textMuted,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceElevated,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    color: AppColors.textMuted,
                                    size: 32,
                                  ),
                                ),
                              ),

                        // Subtle dark overlay
                        Container(
                          color: Colors.black.withAlpha((0.25 * 255).round()),
                        ),

                        // Center Play Button Overlay
                        Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  Colors.black.withAlpha((0.75 * 255).round()),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(
                                  (0.3 * 255).round(),
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),

                        // Episode Indicator Badge (Top Right)
                        if (isTv &&
                            progress?.seasonNumber != null &&
                            progress?.episodeNumber != null)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(
                                  (0.85 * 255).round(),
                                ),
                                borderRadius: AppTokens.borderRadiusSmall,
                                border: Border.all(
                                  color: Colors.white12,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'S${progress!.seasonNumber}:E${progress.episodeNumber}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                        // Bottom Linear Progress Track
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(
                                AppTokens.radiusSmall,
                              ),
                              bottomRight: Radius.circular(
                                AppTokens.radiusSmall,
                              ),
                            ),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 4,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accentPink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),
                // Title and Remaining Meta
                Text(
                  widget.item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (progress != null && progress.remainingMinutes > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${progress.remainingMinutes}m remaining',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
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
