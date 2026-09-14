import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
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
                  return const DiscoveryShimmerSkeleton();
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
              onCastTap: () => DiscoveryDialogs.showCastDialog(context),
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
                  onTap: () => DiscoveryDialogs.showCategoriesModal(context),
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
}
