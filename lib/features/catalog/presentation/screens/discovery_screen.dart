import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
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
    context.read<LibraryBloc>().add(LoadLibraryEvent());
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
    context.read<LibraryBloc>().add(LoadLibraryEvent());
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
          builder: (context, catalogState) {
            if (catalogState.status == CatalogStatus.loading && catalogState.trending.isEmpty) {
              return _buildShimmerSkeleton(context);
            }

            final heroItems = catalogState.trending.take(5).toList();

            return BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, libraryState) {
                final continueWatchingItems = libraryState.continueWatching
                    .where((item) => item.progress != null && !item.progress!.isFinished)
                    .toList();

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

                    // Continue Watching Shelf
                    if (continueWatchingItems.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildContinueWatchingSection(context, continueWatchingItems),
                      ),

                    // Trending Combined Shelf
                    if (catalogState.trending.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildSection(
                          context,
                          title: 'Trending Today',
                          subtitle: 'Top aggregated movies & series across platforms',
                          items: catalogState.trending.skip(heroItems.length).toList(),
                        ),
                      ),

                    // Trending Movies Shelf
                    if (catalogState.trendingMovies.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildSection(
                          context,
                          title: 'Trending Movies',
                          subtitle: 'Most watched movies today',
                          items: catalogState.trendingMovies,
                        ),
                      ),

                    // Trending TV Shows Shelf
                    if (catalogState.trendingSeries.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildSection(
                          context,
                          title: 'Trending TV Series',
                          subtitle: 'Binge-worthy shows trending right now',
                          items: catalogState.trendingSeries,
                        ),
                      ),

                    // Popular Blockbusters Shelf
                    if (catalogState.popularMovies.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildSection(
                          context,
                          title: 'Popular Blockbusters',
                          subtitle: 'All-time audience favorites',
                          items: catalogState.popularMovies,
                        ),
                      ),

                    // Popular Series Shelf
                    if (catalogState.popularSeries.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildSection(
                          context,
                          title: 'Critically Acclaimed TV',
                          subtitle: 'Top rated series',
                          items: catalogState.popularSeries,
                        ),
                      ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 36),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueWatchingSection(
    BuildContext context,
    List<LibraryItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: AppTheme.primaryAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Continue Watching',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 145,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildContinueWatchingCard(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueWatchingCard(BuildContext context, LibraryItem item) {
    final progress = item.progress;
    final percent = progress?.percentage ?? 0.0;
    final isTv = item.type == 'series' || item.type == 'tv';

    final mediaUrl = item.backdropPath != null
        ? (item.backdropPath!.startsWith('http')
            ? item.backdropPath!
            : 'https://image.tmdb.org/t/p/w780${item.backdropPath}')
        : (item.posterPath != null
            ? (item.posterPath!.startsWith('http')
                ? item.posterPath!
                : 'https://image.tmdb.org/t/p/w500${item.posterPath}')
            : null);

    return GestureDetector(
      onTap: () {
        final parsedId = int.tryParse(item.id) ?? 0;
        final mediaItem = MediaItem(
          id: parsedId,
          imdbId: item.id.startsWith('tt') ? item.id : null,
          title: item.title,
          overview: '',
          posterPath: item.posterPath,
          backdropPath: item.backdropPath,
          type: isTv ? MediaType.series : MediaType.movie,
          voteAverage: 0.0,
        );
        context.push('/detail/${mediaItem.type.name}/${mediaItem.id}', extra: mediaItem);
      },
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 110,
                    width: 220,
                    color: AppTheme.surfaceCard,
                    child: mediaUrl != null
                        ? CachedNetworkImage(
                            imageUrl: mediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTheme.surfaceElevated),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.play_circle_outline, color: AppTheme.textMuted),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.play_circle_outline, color: AppTheme.textMuted),
                          ),
                  ),
                ),
                // Play overlay button
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.6 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Progress Bar at bottom of thumbnail
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 4,
                      backgroundColor: Colors.white.withAlpha((0.3 * 255).round()),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                    ),
                  ),
                ),
                // Episode indicator chip
                if (isTv && progress?.seasonNumber != null && progress?.episodeNumber != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.75 * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'S${progress!.seasonNumber} E${progress.episodeNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

  Widget _buildShimmerSkeleton(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.52;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Shimmer Banner
          Stack(
            children: [
              _buildShimmerBox(
                width: double.infinity,
                height: height,
                borderRadius: 0,
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 100, height: 12, borderRadius: 4),
                    const SizedBox(height: 10),
                    _buildShimmerBox(width: 240, height: 26, borderRadius: 6),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildShimmerBox(width: 50, height: 20, borderRadius: 4),
                        const SizedBox(width: 10),
                        _buildShimmerBox(width: 40, height: 20, borderRadius: 4),
                        const SizedBox(width: 10),
                        _buildShimmerBox(width: 60, height: 20, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildShimmerBox(width: 120, height: 38, borderRadius: 8),
                        const SizedBox(width: 12),
                        _buildShimmerBox(width: 100, height: 38, borderRadius: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Shelves Shimmer
          for (int s = 0; s < 2; s++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 160, height: 18, borderRadius: 4),
                  const SizedBox(height: 6),
                  _buildShimmerBox(width: 220, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 225,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, __) {
                  return SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildShimmerBox(
                            width: 130,
                            height: double.infinity,
                            borderRadius: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildShimmerBox(width: 110, height: 12, borderRadius: 3),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: 70, height: 10, borderRadius: 3),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceElevated,
            AppTheme.surfaceElevated.withAlpha((0.6 * 255).round()),
            AppTheme.surfaceElevated,
          ],
        ),
      ),
    );
  }
}
