import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../core/presentation/primitives/aura_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../domain/entities/media_item.dart';

/// Netflix-style Desktop Hover Expansion Preview Card.
/// On mouse hover (>350ms), smoothly elevates and expands 1.15x revealing
/// high-resolution key art/clearart logo, match %, age rating, resolution badges,
/// and instant action buttons.
class DesktopHoverPreviewCard extends StatefulWidget {
  final MediaItem item;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onDetailsTap;

  const DesktopHoverPreviewCard({
    super.key,
    required this.item,
    this.width = AppTokens.posterWidthDesktop,
    this.onTap,
    this.onPlayTap,
    this.onDetailsTap,
  });

  @override
  State<DesktopHoverPreviewCard> createState() =>
      _DesktopHoverPreviewCardState();
}

class _DesktopHoverPreviewCardState extends State<DesktopHoverPreviewCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  Timer? _hoverTimer;
  int _userRating = 0; // 0: none, 2: thumbs up

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _onEnter() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) {
        setState(() => _isHovered = true);
      }
    });
  }

  void _onExit() {
    _hoverTimer?.cancel();
    if (_isHovered) {
      setState(() => _isHovered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width / AppTokens.posterAspectRatio;
    final item = widget.item;
    final isTv = item.type == MediaType.series;

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: height,
        transform: _isHovered
            ? Matrix4.diagonal3Values(1.10, 1.10, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: AuraCard(
          width: widget.width,
          height: height,
          borderRadius: AppTokens.borderRadiusCard,
          onTap: widget.onTap ?? widget.onDetailsTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Poster Art (Default) or Backdrop Art (Hovered)
              ClipRRect(
                borderRadius: AppTokens.borderRadiusCard,
                child: CachedNetworkImage(
                  imageUrl: _isHovered && item.backdropPath != null
                      ? item.highDefBackdropUrl
                      : item.highDefPosterUrl.isNotEmpty
                          ? item.highDefPosterUrl
                          : item.fullPosterUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder: (_, __) =>
                      Container(color: AppColors.surfaceElevated),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.surfaceElevated),
                ),
              ),

              // 2. Subtle Dark Gradient Scrim when hovered
              if (_isHovered)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppTokens.borderRadiusCard,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.40, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. ClearArt Logo or Title
              if (_isHovered)
                Positioned(
                  top: 12,
                  left: 10,
                  right: 10,
                  child: item.logoUrl != null && item.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.logoUrl!,
                          height: 36,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          placeholder: (_, __) => const SizedBox(height: 36),
                          errorWidget: (_, __, ___) => Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

              // 4. Hover Metadata & Action Controls
              if (_isHovered)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Action Buttons Row
                      BlocBuilder<LibraryBloc, LibraryState>(
                        builder: (context, libState) {
                          final isInWatchlist = libState.watchlist.any(
                            (w) => w.id == item.id.toString(),
                          );

                          return Row(
                            children: [
                              // Play Button
                              _CircleActionButton(
                                icon: Icons.play_arrow_rounded,
                                isPrimary: true,
                                onTap: () => widget.onPlayTap?.call(),
                              ),
                              const SizedBox(width: 8),

                              // My List Toggle
                              _CircleActionButton(
                                icon: isInWatchlist ? Icons.check : Icons.add,
                                isActive: isInWatchlist,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.read<LibraryBloc>().add(
                                        ToggleWatchlistEvent(
                                          LibraryItem(
                                            id: item.id.toString(),
                                            title: item.title,
                                            type: isTv ? 'series' : 'movie',
                                            category: LibraryCategory.watchlist,
                                            posterPath: item.posterPath,
                                            backdropPath: item.backdropPath,
                                            updatedAt: DateTime.now(),
                                          ),
                                        ),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),

                              // Thumbs Up Rating
                              _CircleActionButton(
                                icon: _userRating == 2
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                isActive: _userRating == 2,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _userRating = _userRating == 2 ? 0 : 2;
                                  });
                                },
                              ),
                              const Spacer(),

                              // Info / Details Button
                              _CircleActionButton(
                                icon: Icons.keyboard_arrow_down_rounded,
                                onTap: () => widget.onDetailsTap?.call(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // Match % and Metadata Badges Row
                      Row(
                        children: [
                          Text(
                            '98% Match',
                            style: context.auraText.caption.copyWith(
                              color: AppColors.successAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white30),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              item.certification ?? (isTv ? 'TV-MA' : 'PG-13'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const AuraBadge(
                            label: '4K HDR',
                            backgroundColor: Colors.transparent,
                            borderColor: Colors.white30,
                            textColor: Colors.white,
                            fontSize: 9,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Genres Snippet
                      Text(
                        item.genres.isNotEmpty
                            ? item.genres.take(3).map((g) => g.name).join(' • ')
                            : (isTv ? 'Series' : 'Movie'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.auraText.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isActive;

  const _CircleActionButton({
    required this.icon,
    this.onTap,
    this.isPrimary = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary
              ? Colors.white
              : isActive
                  ? AppColors.accentPink
                  : AppColors.surfaceElevated.withValues(alpha: 0.8),
          border: Border.all(
            color: isPrimary || isActive ? Colors.transparent : Colors.white24,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: isPrimary
                ? Colors.black
                : isActive
                    ? Colors.white
                    : Colors.white70,
          ),
        ),
      ),
    );
  }
}
