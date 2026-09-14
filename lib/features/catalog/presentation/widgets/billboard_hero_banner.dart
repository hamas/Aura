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
  double _playScale = 1.0;
  double _infoScale = 1.0;

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
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _buildHeroSlide(context, item, bannerHeight, index);
            },
          ),
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
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSlide(
      BuildContext context, MediaItem item, double height, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
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
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 0.65, 1.0],
                colors: [
                  Color(0x66141414),
                  Colors.transparent,
                  Color(0x80141414),
                  AppColors.surfaceBackground,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index < 10) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  ),
                  child: Text(
                    'TOP 10',
                    style: context.auraText.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
              Text(
                item.title,
                style: context.auraText.displayHero.copyWith(fontSize: 28),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Gritty • Psychological • Mystery',
                style: context.auraText.caption.copyWith(
                  color: const Color(0xFFE5E5E5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTapDown: (_) => setState(() => _playScale = 0.96),
                    onTapUp: (_) {
                      setState(() => _playScale = 1.0);
                      widget.onPlayTap?.call(item);
                    },
                    onTapCancel: () => setState(() => _playScale = 1.0),
                    child: Transform.scale(
                      scale: _playScale,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Color(0xFF000000), size: 24),
                            const SizedBox(width: 6),
                            Text(
                              'Play',
                              style: context.auraText.itemTitle.copyWith(
                                color: const Color(0xFF000000),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTapDown: (_) => setState(() => _infoScale = 0.96),
                    onTapUp: (_) {
                      setState(() => _infoScale = 1.0);
                      widget.onDetailsTap?.call(item);
                    },
                    onTapCancel: () => setState(() => _infoScale = 1.0),
                    child: Transform.scale(
                      scale: _infoScale,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Color(0xFFFFFFFF), size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Info',
                              style: context.auraText.itemTitle.copyWith(
                                color: const Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
