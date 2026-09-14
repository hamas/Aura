import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../domain/entities/media_item.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/widgets.dart';

/// Netflix-style cinematic Discovery & Home screen for Aura.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final ScrollController _scrollController = ScrollController();
  double _navOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadDiscoveryFeedsEvent());
    context.read<LibraryBloc>().add(LoadLibraryEvent());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final newOpacity = (offset / 140.0).clamp(0.0, 1.0);
    if ((newOpacity - _navOpacity).abs() > 0.01) {
      setState(() {
        _navOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<CatalogBloc>().add(LoadDiscoveryFeedsEvent());
    context.read<LibraryBloc>().add(LoadLibraryEvent());
  }

  void _navigateToDetail(MediaItem item) {
    context.push('/detail/${item.type.name}/${item.id}', extra: item);
  }

  void _onContinueWatchingTap(LibraryItem item) {
    final parsedId = int.tryParse(item.id) ?? 0;
    final isTv = item.type == 'series' || item.type == 'tv';
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
    _navigateToDetail(mediaItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          // Main Scrollable Content
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.accentPink,
            backgroundColor: AppColors.surfaceElevated,
            child: BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, catalogState) {
                if (catalogState.status == CatalogStatus.loading &&
                    catalogState.trending.isEmpty) {
                  return _buildNetflixShimmerSkeleton(context);
                }

                final heroItems = catalogState.trending.take(5).toList();

                return BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, libraryState) {
                    final continueWatchingItems = libraryState.continueWatching
                        .where((item) =>
                            item.progress != null && !item.progress!.isFinished)
                        .toList();

                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // 1. Billboard Hero Banner
                        if (heroItems.isNotEmpty)
                          SliverToBoxAdapter(
                            child: BillboardHeroBanner(
                              items: heroItems,
                              onPlayTap: _navigateToDetail,
                              onDetailsTap: _navigateToDetail,
                            ),
                          ),

                        // 2. Shelf: Continue Watching (16:9 cards)
                        if (continueWatchingItems.isNotEmpty)
                          SliverToBoxAdapter(
                            child: HorizontalContentShelf<LibraryItem>(
                              title: 'Continue Watching',
                              subtitle: 'Resume playback where you left off',
                              items: continueWatchingItems,
                              height: 165,
                              itemSpacing: 14,
                              itemBuilder: (context, item, index) {
                                return ContinueWatchingCard(
                                  item: item,
                                  onTap: () => _onContinueWatchingTap(item),
                                );
                              },
                            ),
                          ),

                        // 3. Shelf: Trending Movies (2:3 vertical posters)
                        if (catalogState.trendingMovies.isNotEmpty)
                          SliverToBoxAdapter(
                            child: HorizontalContentShelf.media(
                              title: 'Trending Movies',
                              subtitle: 'Top worldwide cinema releases',
                              items: catalogState.trendingMovies,
                              onItemTap: _navigateToDetail,
                            ),
                          ),

                        // 4. Shelf: Popular TV Shows (2:3 vertical posters)
                        if (catalogState.trendingSeries.isNotEmpty)
                          SliverToBoxAdapter(
                            child: HorizontalContentShelf.media(
                              title: 'Popular TV Shows',
                              subtitle: 'Binge-worthy series trending today',
                              items: catalogState.trendingSeries,
                              onItemTap: _navigateToDetail,
                            ),
                          ),

                        // 5. Shelf: Trending Combined & Community Picks
                        if (catalogState.trending.length > 5)
                          SliverToBoxAdapter(
                            child: HorizontalContentShelf.media(
                              title: 'Community Picks & Trending',
                              subtitle: 'Aggregated community favorites',
                              items: catalogState.trending.skip(5).toList(),
                              onItemTap: _navigateToDetail,
                            ),
                          ),

                        // 6. Shelf: Critically Acclaimed Series
                        if (catalogState.popularSeries.isNotEmpty)
                          SliverToBoxAdapter(
                            child: HorizontalContentShelf.media(
                              title: 'Critically Acclaimed Series',
                              subtitle: 'Top rated worldwide television',
                              items: catalogState.popularSeries,
                              onItemTap: _navigateToDetail,
                            ),
                          ),

                        // 7. Shelf: Popular Blockbusters
                        if (catalogState.popularMovies.isNotEmpty)
                          SliverToBoxAdapter(
                            child: HorizontalContentShelf.media(
                              title: 'Blockbuster Cinema',
                              subtitle: 'All-time audience blockbusters',
                              items: catalogState.popularMovies,
                              onItemTap: _navigateToDetail,
                            ),
                          ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 48),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Sticky Translucent Netflix Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyTopNavBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTopNavBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(18, topPadding + 6, 14, 10),
      decoration: BoxDecoration(
        color:
            AppColors.surfaceBackground.withAlpha((_navOpacity * 255).round()),
        boxShadow: _navOpacity > 0.4
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha((0.6 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Aura Brand Wordmark
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AURA',
                style: TextStyle(
                  color: AppColors.accentPink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Search Action Icon
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            tooltip: 'Search media',
          ),

          // Profile / Avatar Action
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final user = authState.user;
              return GestureDetector(
                onTap: () => context.push('/settings'),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppTokens.borderRadiusSmall,
                    border: Border.all(
                      color: authState.isAuthenticated
                          ? AppColors.accentPink
                          : const Color(0xFF333333),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppTokens.radiusSmall - 1),
                    child: user?.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: user!.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.surfaceElevated,
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNetflixShimmerSkeleton(BuildContext context) {
    final heroHeight = MediaQuery.of(context).size.height * 0.58;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Shimmer
          Stack(
            children: [
              _buildShimmerBox(
                width: double.infinity,
                height: heroHeight,
                borderRadius: 0,
              ),
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(
                      width: 80,
                      height: 12,
                      borderRadius: AppTokens.radiusSmall,
                    ),
                    const SizedBox(height: 10),
                    _buildShimmerBox(
                      width: 240,
                      height: 28,
                      borderRadius: AppTokens.radiusSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildShimmerBox(
                          width: 50,
                          height: 20,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                        const SizedBox(width: 8),
                        _buildShimmerBox(
                          width: 44,
                          height: 20,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                        const SizedBox(width: 8),
                        _buildShimmerBox(
                          width: 60,
                          height: 20,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildShimmerBox(
                          width: 110,
                          height: 38,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                        const SizedBox(width: 10),
                        _buildShimmerBox(
                          width: 100,
                          height: 38,
                          borderRadius: AppTokens.radiusSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Shelves Shimmers
          for (int s = 0; s < 2; s++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _buildShimmerBox(
                width: 160,
                height: 18,
                borderRadius: AppTokens.radiusSmall,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) {
                  return _buildShimmerBox(
                    width: AppTokens.posterWidthMobile,
                    height: 180,
                    borderRadius: AppTokens.radiusSmall,
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFF262626), width: 0.8),
      ),
    );
  }
}
