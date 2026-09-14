import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    this.autoScroll = false,
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
        widget.height ?? MediaQuery.of(context).size.height * 0.55;

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
    final primaryGenre =
        item.genres.isNotEmpty ? item.genres.first.name : 'Movie';
    final year = item.releaseYear;
    final metadataText = year.isNotEmpty ? '$primaryGenre  •  $year' : primaryGenre;

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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: context.auraText.displayHero.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 10.0,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metadataText,
                    style: context.auraText.caption.copyWith(
                      color: const Color(0xFFE5E5E5),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () => widget.onDetailsTap?.call(item),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x33FFFFFF),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
