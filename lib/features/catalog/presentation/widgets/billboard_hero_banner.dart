import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/media_item.dart';

/// Full-bleed Netflix-style Billboard Hero Banner with dual vignettes and action buttons.
class BillboardHeroBanner extends StatefulWidget {
  final List<MediaItem> items;
  final void Function(MediaItem item)? onPlayTap;
  final void Function(MediaItem item)? onDetailsTap;
  final double? height;
  final bool autoScroll;

  const BillboardHeroBanner({
    super.key,
    required this.items,
    this.onPlayTap,
    this.onDetailsTap,
    this.height,
    this.autoScroll = true,
  });

  @override
  State<BillboardHeroBanner> createState() => _BillboardHeroBannerState();
}

class _BillboardHeroBannerState extends State<BillboardHeroBanner> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoScroll && widget.items.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted || !_pageController.hasClients || widget.items.isEmpty) {
        return;
      }
      final nextPage = (_currentPage + 1) % widget.items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant BillboardHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      if (widget.autoScroll && widget.items.length > 1) {
        _startAutoScroll();
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final bannerHeight =
        widget.height ?? MediaQuery.of(context).size.height * 0.60;

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          // Page View Carousel
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildHeroSlide(context, item, bannerHeight);
            },
          ),

          // Carousel Page Indicator Dots
          if (widget.items.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 22 : 6,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.accentPink
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: _currentPage == index
                          ? [
                              BoxShadow(
                                color: AppColors.accentPink.withAlpha(
                                  (0.6 * 255).round(),
                                ),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSlide(BuildContext context, MediaItem item, double height) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop image
        item.backdropPath != null
            ? CachedNetworkImage(
                imageUrl: item.fullBackdropUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceBackground),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceBackground),
              )
            : Container(color: AppColors.surfaceBackground),

        // Top Vignette (Dark gradient for nav and status bar)
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.heroTopVignette),
          ),
        ),

        // Bottom Vignette (Seamless blend into shelf canvas)
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.heroBottomVignette),
          ),
        ),

        // Hero Content Overlay
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tagline or Category Pill
              if (item.tagline != null && item.tagline!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    item.tagline!.toUpperCase(),
                    style: AppTypography.metadataPill.copyWith(
                      color: AppColors.accentPink,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Title
              Text(
                item.title,
                style: AppTypography.displayHero.copyWith(
                  fontSize: 28,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Metadata Badges Row
              Row(
                children: [
                  // Star Rating Badge
                  AuraBadge.rating(item.formattedRating),
                  const SizedBox(width: 8),

                  // 4K / Ultra HD Badge
                  AuraBadge.quality('4K HDR'),
                  const SizedBox(width: 8),

                  // Release Year
                  if (item.releaseYear.isNotEmpty) ...[
                    Text(
                      item.releaseYear,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Media Type (Movie/Series)
                  AuraBadge(
                    label: item.type == MediaType.movie ? 'MOVIE' : 'SERIES',
                    backgroundColor: AppColors.surfaceElevated,
                    borderColor: const Color(0x33FFFFFF),
                    textColor: AppColors.textMuted,
                  ),
                ],
              ),

              // Short Synopsis (2-line clamp)
              if (item.overview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.overview,
                  style: AppTypography.bodyOverview.copyWith(
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),

              // Action Buttons Row
              Row(
                children: [
                  // Play Button (High Emphasis Electric Violet/Pink Pill)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPink,
                      foregroundColor: const Color(0xFF0E0F12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppTokens.borderRadiusSmall,
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      if (widget.onPlayTap != null) {
                        widget.onPlayTap!(item);
                      }
                    },
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: 22,
                      color: Color(0xFF0E0F12),
                    ),
                    label: const Text(
                      'Play',
                      style: TextStyle(
                        color: Color(0xFF0E0F12),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Info / Details Button (Glass Pill)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      backgroundColor: AppColors.glassWhite,
                      side: const BorderSide(color: Colors.white24, width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppTokens.borderRadiusSmall,
                      ),
                    ),
                    onPressed: () {
                      if (widget.onDetailsTap != null) {
                        widget.onDetailsTap!(item);
                      }
                    },
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    label: const Text(
                      'Details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
