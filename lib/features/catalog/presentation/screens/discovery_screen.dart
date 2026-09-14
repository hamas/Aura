import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/media_item.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final PageController _heroPageController = PageController();
  int _currentHeroPage = 0;
  Timer? _heroAutoScrollTimer;

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadDiscoveryFeedsEvent());
    _startHeroAutoScroll();
  }

  void _startHeroAutoScroll() {
    _heroAutoScrollTimer?.cancel();
    _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted || !_heroPageController.hasClients) return;
      final nextPage = (_currentHeroPage + 1) % 5;
      _heroPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _heroAutoScrollTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<CatalogBloc>().add(LoadDiscoveryFeedsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.surfaceElevated,
        child: BlocBuilder<CatalogBloc, CatalogState>(
          builder: (context, state) {
            if (state.status == CatalogStatus.loading && state.trending.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryAccent),
              );
            }

            final heroItems = state.trending.take(5).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Multi-item Hero Backdrop Carousel
                if (heroItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildHeroCarousel(context, heroItems),
                  ),

                // Trending Combined Shelf
                if (state.trending.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSection(
                      context,
                      title: 'Trending Today',
                      subtitle: 'Top aggregated movies & series across platforms',
                      items: state.trending.skip(heroItems.length).toList(),
                    ),
                  ),

                // Trending Movies Shelf
                if (state.trendingMovies.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSection(
                      context,
                      title: 'Trending Movies',
                      subtitle: 'Most watched movies today',
                      items: state.trendingMovies,
                    ),
                  ),

                // Trending TV Shows Shelf
                if (state.trendingSeries.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSection(
                      context,
                      title: 'Trending TV Series',
                      subtitle: 'Binge-worthy shows trending right now',
                      items: state.trendingSeries,
                    ),
                  ),

                // Popular Blockbusters Shelf
                if (state.popularMovies.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSection(
                      context,
                      title: 'Popular Blockbusters',
                      subtitle: 'All-time audience favorites',
                      items: state.popularMovies,
                    ),
                  ),

                // Popular Series Shelf
                if (state.popularSeries.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildSection(
                      context,
                      title: 'Critically Acclaimed TV',
                      subtitle: 'Top rated series',
                      items: state.popularSeries,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 36),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCarousel(BuildContext context, List<MediaItem> heroItems) {
    final height = MediaQuery.of(context).size.height * 0.58;

    return Stack(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: heroItems.length,
            onPageChanged: (index) {
              setState(() {
                _currentHeroPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = heroItems[index];
              return _buildHeroSlide(context, item, height);
            },
          ),
        ),

        // Carousel Page Indicators (Bottom Center)
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              heroItems.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentHeroPage == index ? 24 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentHeroPage == index
                      ? AppTheme.primaryAccent
                      : Colors.white.withAlpha((0.25 * 255).round()),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: _currentHeroPage == index
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryAccent.withAlpha((0.6 * 255).round()),
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
    );
  }

  Widget _buildHeroSlide(BuildContext context, MediaItem item, double height) {
    return GestureDetector(
      onTap: () => context.push('/detail/${item.type.name}/${item.id}', extra: item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop Image
          item.backdropPath != null
              ? CachedNetworkImage(
                  imageUrl: item.fullBackdropUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surface),
                  errorWidget: (_, __, ___) => Container(color: AppTheme.surface),
                )
              : Container(color: AppTheme.surface),

          // Vignette and Contrast Gradients
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x800A0D14),
                  Colors.transparent,
                  Color(0xCC0A0D14),
                  AppTheme.background,
                ],
                stops: [0.0, 0.25, 0.75, 1.0],
              ),
            ),
          ),

          // Hero Slide Metadata
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tagline / Category Pill
                if (item.tagline != null && item.tagline!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      item.tagline!.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Main Title
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Meta Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAccent.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.warningAccent, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.warningAccent, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            item.formattedRating,
                            style: const TextStyle(
                              color: AppTheme.warningAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (item.releaseYear.isNotEmpty) ...[
                      Text(
                        item.releaseYear,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type == MediaType.movie ? 'MOVIE' : 'SERIES',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/detail/${item.type.name}/${item.id}',
                        extra: item,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Watch Now'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2E384D)),
                        backgroundColor: Colors.black.withAlpha((0.3 * 255).round()),
                      ),
                      onPressed: () => context.push(
                        '/detail/${item.type.name}/${item.id}',
                        extra: item,
                      ),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<MediaItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 225,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildMediaCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(BuildContext context, MediaItem item) {
    return GestureDetector(
      onTap: () => context.push('/detail/${item.type.name}/${item.id}', extra: item),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: AppTheme.surfaceCard,
                  child: item.posterPath != null
                      ? CachedNetworkImage(
                          imageUrl: item.fullPosterUrl,
                          fit: BoxFit.cover,
                          width: 130,
                          placeholder: (_, __) => Container(color: AppTheme.surfaceElevated),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.movie, color: AppTheme.textMuted),
                          ),
                        )
                      : const Center(child: Icon(Icons.movie, color: AppTheme.textMuted)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                const Icon(Icons.star, color: AppTheme.warningAccent, size: 12),
                const SizedBox(width: 3),
                Text(
                  item.formattedRating,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  item.releaseYear,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
