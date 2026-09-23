import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/media_item.dart';

class BillboardHeroBanner extends StatefulWidget {
  final List<MediaItem> items;
  final void Function(MediaItem item)? onPlayTap;
  final void Function(MediaItem item)? onDetailsTap;
  final double? height;
  final bool autoScroll;
  final int? activeIndex;

  const BillboardHeroBanner({
    super.key,
    required this.items,
    this.onPlayTap,
    this.onDetailsTap,
    this.height,
    this.autoScroll = false,
    this.activeIndex,
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

  @override
  void didUpdateWidget(BillboardHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != null &&
        widget.activeIndex != _currentPage &&
        widget.activeIndex! >= 0 &&
        widget.activeIndex! < widget.items.length &&
        _pageController.hasClients) {
      _currentPage = widget.activeIndex!;
      _pageController.animateToPage(
        widget.activeIndex!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
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

    final heroHeight = MediaQuery.sizeOf(context).height * 0.55;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildHeroSlide(context, item, heroHeight, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSlide(
      BuildContext context, MediaItem item, double height, int index) {
    final genresList = item.genres.isNotEmpty
        ? item.genres.take(3).map((g) => g.name).toList()
        : ['Featured'];
    final year = item.releaseYear;
    final genreYearString = year.isNotEmpty
        ? '${genresList.join(' • ')} • $year'
        : genresList.join(' • ');

    return InkWell(
      onTap: () {
        if (widget.onDetailsTap != null) {
          widget.onDetailsTap!(item);
        } else if (widget.onPlayTap != null) {
          widget.onPlayTap!(item);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A. Backdrop / Key Art Presentation
          item.backdropPath != null
              ? CachedNetworkImage(
                  imageUrl: item.fullBackdropUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  placeholder: (_, __) =>
                      Container(color: AppColors.surfaceBackground),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.surfaceBackground),
                )
              : Container(color: AppColors.surfaceBackground),

          // Top 0.0 - 0.20, Mid 0.20 - 0.50, Bottom 0.50 - 1.0 Vignette Scrim Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.20, 0.50, 1.0],
                  colors: [
                    AppColors.surfaceBackground.withValues(alpha: 0.50),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.surfaceBackground,
                  ],
                ),
              ),
            ),
          ),

          // C. Bottom-Aligned Centered Metadata Stack
          Positioned(
            bottom: AppTokens.spacingMd,
            left: AppTokens.screenEdgeHorizontal,
            right: AppTokens.screenEdgeHorizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Ratings Row (Tomatometer & Popcorn)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Critics Rating: Fresh (>=60%) tomato / Rotten (<60%) splat
                    const Text('🍅', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '88%',
                      style: context.auraText.metadataPill.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    // Audience Rating: Fresh (>=60%) popcorn bucket
                    const Text('🍿', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '94%',
                      style: context.auraText.metadataPill.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingSm),

                // 2. Title Logo (Clearart PNG) or Title Text fallback
                if (item.logoUrl != null && item.logoUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: item.logoUrl!,
                    height: 52.0,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    imageBuilder: (context, imageProvider) => Container(
                      constraints: const BoxConstraints(maxWidth: 240.0),
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image(
                        image: imageProvider,
                        height: 52.0,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                    placeholder: (_, __) => const SizedBox(height: 52.0),
                    errorWidget: (_, __, ___) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.auraText.displayHero.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.auraText.displayHero.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppTokens.spacingXs),

                // 3. Genres & Year Line
                Text(
                  genreYearString,
                  style: context.auraText.caption.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 20px space between content (genre + year) and slider dots
                const SizedBox(height: 20.0),

                // 4. White 50% Smaller Slider Dots
                if (widget.items.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.items.length,
                      (dotIndex) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        width: _currentPage == dotIndex ? 11.0 : 3.0,
                        height: 2.0,
                        decoration: BoxDecoration(
                          color: _currentPage == dotIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
