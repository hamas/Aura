import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/domain/entities/library_item.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../../../library/presentation/bloc/library_event.dart';
import '../../../library/presentation/bloc/library_state.dart';
import '../../domain/entities/media_item.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/components/discovery_dialogs.dart';
import '../widgets/components/discovery_shimmer_skeleton.dart';
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

  int _heroActiveIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<CatalogBloc>().add(LoadDiscoveryFeedsEvent());
    context.read<LibraryBloc>().add(LoadLibraryEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentScroll = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Update hero slider index based on scroll distance (e.g. every ~180px of scroll shifts to next hero item)
      final catalogBloc = context.read<CatalogBloc>();
      final heroCount = catalogBloc.state.trending.take(5).length;
      if (heroCount > 0) {
        final newHeroIndex =
            (currentScroll / 180.0).floor().clamp(0, heroCount - 1);
        if (newHeroIndex != _heroActiveIndex) {
          setState(() {
            _heroActiveIndex = newHeroIndex;
          });
        }
      }

      if (currentScroll >= maxScroll - 400) {
        context.read<CatalogBloc>().add(LoadMoreCatalogEvent());
      }
    }
  }

  Future<void> _onRefresh() async {
    final catalogBloc = context.read<CatalogBloc>();
    final libraryBloc = context.read<LibraryBloc>();

    catalogBloc.add(LoadDiscoveryFeedsEvent());
    libraryBloc.add(LoadLibraryEvent());

    try {
      await catalogBloc.stream.firstWhere(
        (state) =>
            state.status == CatalogStatus.success ||
            state.status == CatalogStatus.failure,
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
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
    final topBarOffset = MediaQuery.of(context).padding.top + 60.0;

    return AuraScaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            backgroundColor: AppColors.surfaceElevated,
            strokeWidth: 2.0,
            edgeOffset: topBarOffset,
            displacement: 24.0,
            child: BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, catalogState) {
                if (catalogState.status == CatalogStatus.loading &&
                    catalogState.trending.isEmpty) {
                  return const DiscoveryShimmerSkeleton();
                }

                final candidateHeroPool = _selectedFilter ==
                        MediaCategoryFilter.movies
                    ? (catalogState.trendingMovies.isNotEmpty
                        ? catalogState.trendingMovies
                        : catalogState.trending
                            .where((m) => m.type == MediaType.movie)
                            .toList())
                    : _selectedFilter == MediaCategoryFilter.tvShows
                        ? (catalogState.trendingSeries.isNotEmpty
                            ? catalogState.trendingSeries
                            : catalogState.trending
                                .where((m) => m.type == MediaType.series)
                                .toList())
                        : catalogState.trending;

                // Dedicated Tier-1 Hero Selection Algorithm:
                // Vote count >= 500, vote average >= 6.8, with valid backdrop & logo.
                final prestigeHeroPool = candidateHeroPool.where((item) {
                  final hasValidLogo =
                      item.logoPath != null && item.logoPath!.isNotEmpty;
                  final hasValidBackdrop = item.backdropPath != null &&
                      item.backdropPath!.isNotEmpty;
                  return item.voteCount >= 500 &&
                      item.voteAverage >= 6.8 &&
                      hasValidBackdrop &&
                      hasValidLogo;
                }).toList();

                final List<MediaItem> heroItems;
                if (prestigeHeroPool.isNotEmpty) {
                  heroItems = prestigeHeroPool.take(5).toList();
                } else {
                  final withLogos = candidateHeroPool
                      .where((item) =>
                          item.logoPath != null && item.logoPath!.isNotEmpty)
                      .toList();
                  if (withLogos.isNotEmpty) {
                    heroItems = withLogos.take(5).toList();
                  } else {
                    final withBackdrops = candidateHeroPool
                        .where((item) =>
                            item.backdropPath != null &&
                            item.backdropPath!.isNotEmpty)
                        .toList();
                    heroItems = withBackdrops.isNotEmpty
                        ? withBackdrops.take(5).toList()
                        : candidateHeroPool.take(5).toList();
                  }
                }

                final rawGridItems = catalogState.gridItems;
                final List<MediaItem> gridItems;
                if (_selectedFilter == MediaCategoryFilter.movies) {
                  gridItems = rawGridItems
                      .where((item) => item.type == MediaType.movie)
                      .toList();
                } else if (_selectedFilter == MediaCategoryFilter.tvShows) {
                  gridItems = rawGridItems
                      .where((item) => item.type == MediaType.series)
                      .toList();
                } else {
                  gridItems = rawGridItems;
                }

                final List<MediaItem> latestItems;
                if (_selectedFilter == MediaCategoryFilter.movies) {
                  latestItems = catalogState.latestMovies.isNotEmpty
                      ? catalogState.latestMovies
                      : catalogState.trendingMovies;
                } else if (_selectedFilter == MediaCategoryFilter.tvShows) {
                  latestItems = catalogState.latestSeries.isNotEmpty
                      ? catalogState.latestSeries
                      : catalogState.trendingSeries;
                } else {
                  final combined = [
                    ...catalogState.latestMovies,
                    ...catalogState.latestSeries
                  ];
                  latestItems =
                      combined.isNotEmpty ? combined : catalogState.trending;
                }

                return BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, libraryState) {
                    final continueWatchingItems = libraryState.continueWatching
                        .where((item) =>
                            item.progress != null && !item.progress!.isFinished)
                        .toList();

                    // Filter My List (watchlist) based on selected category filter
                    final List<MediaItem> myListItems =
                        libraryState.watchlist.where((item) {
                      if (_selectedFilter == MediaCategoryFilter.movies) {
                        return item.type == 'movie';
                      } else if (_selectedFilter ==
                          MediaCategoryFilter.tvShows) {
                        return item.type == 'series' || item.type == 'tv';
                      }
                      return true;
                    }).map((item) {
                      final parsedId = int.tryParse(item.id) ?? 0;
                      final isTv = item.type == 'series' || item.type == 'tv';
                      return MediaItem(
                        id: parsedId,
                        imdbId: item.id.startsWith('tt') ? item.id : null,
                        title: item.title,
                        overview: '',
                        posterPath: item.posterPath,
                        backdropPath: item.backdropPath,
                        type: isTv ? MediaType.series : MediaType.movie,
                        voteAverage: 0.0,
                      );
                    }).toList();

                    return MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (heroItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: BillboardHeroBanner(
                                items: heroItems,
                                activeIndex: _heroActiveIndex,
                                onPlayTap: _navigateToDetail,
                                onDetailsTap: _navigateToDetail,
                              ),
                            ),

                          // My List Slider (Saved movies/shows)
                          if (myListItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'My List',
                                subtitle: 'Saved to your watchlist',
                                items: myListItems,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // Continue Watching Row (16:9 Aspect Ratio)
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

                          // 1. Latest Slider (Respects Selected Category Filter)
                          if (latestItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Latest',
                                items: latestItems,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // 2. Top Movies Slider
                          if (catalogState.trendingMovies.isNotEmpty &&
                              (_selectedFilter == MediaCategoryFilter.all ||
                                  _selectedFilter ==
                                      MediaCategoryFilter.movies))
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Top Movies',
                                items: catalogState.trendingMovies,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // 3. Top Shows Slider
                          if (catalogState.trendingSeries.isNotEmpty &&
                              (_selectedFilter == MediaCategoryFilter.all ||
                                  _selectedFilter ==
                                      MediaCategoryFilter.tvShows))
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Top Shows',
                                items: catalogState.trendingSeries,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // 4. Top International & Asian Dramas
                          if (catalogState.internationalHits.isNotEmpty)
                            SliverToBoxAdapter(
                              child: HorizontalContentShelf.media(
                                title: 'Top International & Asian Dramas',
                                items: catalogState.internationalHits,
                                onItemTap: _navigateToDetail,
                              ),
                            ),

                          // Grid Header
                          if (gridItems.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppTokens.screenEdgeHorizontal,
                                  20,
                                  AppTokens.screenEdgeHorizontal,
                                  12,
                                ),
                                child: Text(
                                  'Explore',
                                  style: context.auraText.sectionTitle.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Infinite Scroll Grid (Lazy loading as user scrolls)
                          if (gridItems.isNotEmpty)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.screenEdgeHorizontal,
                              ),
                              sliver: SliverGrid.builder(
                                itemCount: gridItems.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: AppTokens.posterAspectRatio,
                                  mainAxisSpacing: AppTokens.spacingSm,
                                  crossAxisSpacing: AppTokens.spacingSm,
                                ),
                                itemBuilder: (context, index) {
                                  final item = gridItems[index];
                                  return MediaPosterCard(
                                    item: item,
                                    onTap: () => _navigateToDetail(item),
                                  );
                                },
                              ),
                            ),

                          if (catalogState.isLoadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 80),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Pinned Persistent Category Filter Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              scrollController: _scrollController,
              onCastTap: () => DiscoveryDialogs.showCastDialog(context),
              categories: [
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
                  label: 'Shows',
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
                  label: 'Categories ▾',
                  isSelected: false,
                  onTap: () => DiscoveryDialogs.showCategoriesModal(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
