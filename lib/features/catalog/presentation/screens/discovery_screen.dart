import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../domain/entities/media_item.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/widgets.dart';

enum MediaCategoryFilter { all, tvShows, movies }

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final ScrollController _scrollController = ScrollController();
  MediaCategoryFilter _selectedFilter = MediaCategoryFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadDiscoveryFeedsEvent());
    context.read<LibraryBloc>().add(LoadLibraryEvent());
  }

  @override
  void dispose() {
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

  void _showCastDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Row(
          children: [
            AuraIcon(AppIcons.cast, color: AppColors.accentPink),
            SizedBox(width: 10),
            Text(
              'Connect Device',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Searching for available Chromecast, Android TV, and DLNA display targets on your local network...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close',
                style: TextStyle(color: AppColors.accentPink)),
          ),
        ],
      ),
    );
  }

  void _showCategoriesModal() {
    final genres = [
      'Action & Adventure',
      'Sci-Fi & Cyberpunk',
      'Crime & Mystery',
      'Drama',
      'Comedy',
      'Animation & Anime',
      'Documentary',
      'Thriller & Suspense',
      'Fantasy',
      'Horror',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Browse Categories',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        genre,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const AuraIcon(
                        AppIcons.chevronRight,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surfaceElevated,
                            content: Text('Filtering by "$genre"'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      body: Stack(
        children: [
          // 1. Full-Bleed Scrollable Content starting beneath status bar
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

                List<MediaItem> heroItems;
                if (_selectedFilter == MediaCategoryFilter.movies) {
                  heroItems = catalogState.trendingMovies.take(5).toList();
                } else if (_selectedFilter == MediaCategoryFilter.tvShows) {
                  heroItems = catalogState.trendingSeries.take(5).toList();
                } else {
                  heroItems = catalogState.trending.take(5).toList();
                }

                return BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, libraryState) {
                    final continueWatchingItems = libraryState.continueWatching
                        .where((item) =>
                            item.progress != null && !item.progress!.isFinished)
                        .toList();

                    return MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          // Billboard Hero Banner
                          if (heroItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: BillboardHeroBanner(
                                items: heroItems,
                                onPlayTap: _navigateToDetail,
                                onDetailsTap: _navigateToDetail,
                              ),
                            ),

                          // Continue Watching Shelf
                          if (continueWatchingItems.isNotEmpty &&
                              _selectedFilter == MediaCategoryFilter.all)
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

                          // Trending Movies Shelf
                          if (catalogState.trendingMovies.isNotEmpty &&
                              (_selectedFilter == MediaCategoryFilter.all ||
                                  _selectedFilter ==
                                      MediaCategoryFilter.movies))
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Trending Movies',
                                subtitle: 'Top worldwide cinema releases',
                                items: catalogState.trendingMovies,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // Popular TV Shows Shelf
                          if (catalogState.trendingSeries.isNotEmpty &&
                              (_selectedFilter == MediaCategoryFilter.all ||
                                  _selectedFilter ==
                                      MediaCategoryFilter.tvShows))
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Popular TV Shows',
                                subtitle: 'Binge-worthy series trending today',
                                items: catalogState.trendingSeries,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // Community Picks & Trending Combined
                          if (catalogState.trending.length > 5 &&
                              _selectedFilter == MediaCategoryFilter.all)
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Community Picks & Trending',
                                subtitle: 'Aggregated community favorites',
                                items: catalogState.trending.skip(5).toList(),
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // Critically Acclaimed Series
                          if (catalogState.popularSeries.isNotEmpty &&
                              (_selectedFilter == MediaCategoryFilter.all ||
                                  _selectedFilter ==
                                      MediaCategoryFilter.tvShows))
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Critically Acclaimed Series',
                                subtitle: 'Top rated worldwide television',
                                items: catalogState.popularSeries,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // Blockbuster Cinema
                          if (catalogState.popularMovies.isNotEmpty &&
                              (_selectedFilter == MediaCategoryFilter.all ||
                                  _selectedFilter ==
                                      MediaCategoryFilter.movies))
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
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 2. Netflix-Style Adaptive Header with "A" Brand Glyph
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              scrollController: _scrollController,
              onCastTap: _showCastDialog,
              categories: [
                AuraCategoryPill(
                  label: 'TV Shows',
                  isSelected: _selectedFilter == MediaCategoryFilter.tvShows,
                  onTap: () {
                    setState(() {
                      _selectedFilter =
                          _selectedFilter == MediaCategoryFilter.tvShows
                              ? MediaCategoryFilter.all
                              : MediaCategoryFilter.tvShows;
                    });
                  },
                ),
                AuraCategoryPill(
                  label: 'Movies',
                  isSelected: _selectedFilter == MediaCategoryFilter.movies,
                  onTap: () {
                    setState(() {
                      _selectedFilter =
                          _selectedFilter == MediaCategoryFilter.movies
                              ? MediaCategoryFilter.all
                              : MediaCategoryFilter.movies;
                    });
                  },
                ),
                AuraCategoryPill(
                  label: 'Categories ▾',
                  isSelected: false,
                  onTap: _showCategoriesModal,
                ),
                if (_selectedFilter != MediaCategoryFilter.all)
                  AuraCategoryPill(
                    label: '✕ Clear',
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _selectedFilter = MediaCategoryFilter.all;
                      });
                    },
                  ),
              ],
            ),
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
