import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/tmdb_api_client.dart';
import '../../data/helpers/tmdb_genre_mapper.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/services/media_content_filter.dart';
import '../widgets/billboard_hero_banner.dart';
import '../widgets/media_poster_card.dart';

enum CategoryMediaTypeFilter { movies, shows, short }

enum ShortSortOption { popular, newRelease, featured }

class CategoryScreen extends StatefulWidget {
  final String genreName;

  const CategoryScreen({
    super.key,
    required this.genreName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ScrollController _scrollController = ScrollController();
  late final TmdbApiClient _apiClient;

  CategoryMediaTypeFilter _selectedFilter = CategoryMediaTypeFilter.movies;
  ShortSortOption _selectedShortOption = ShortSortOption.popular;

  List<MediaItem> _items = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  bool _hasMovies = true;
  bool _hasShows = true;

  @override
  void initState() {
    super.initState();
    _apiClient = TmdbApiClient();
    _scrollController.addListener(_onScroll);
    _checkCategoryAvailabilityAndFetch();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 400 &&
          !_isLoadingMore &&
          !_hasReachedMax) {
        _loadMore();
      }
    }
  }

  Future<void> _checkCategoryAvailabilityAndFetch() async {
    final genreId = TmdbGenreMapper.getGenreIdByName(widget.genreName) ?? 28;

    // Check if movies and shows exist for this genre
    final checkMovies = await _apiClient.discoverByGenre(
      genreId: genreId,
      type: MediaType.movie,
      page: 1,
    );
    final checkShows = await _apiClient.discoverByGenre(
      genreId: genreId,
      type: MediaType.series,
      page: 1,
    );

    final hasMovies = checkMovies.isNotEmpty;
    final hasShows = checkShows.isNotEmpty;

    if (mounted) {
      setState(() {
        _hasMovies = hasMovies;
        _hasShows = hasShows;

        // Auto fallback filter if current selected is unavailable
        if (_selectedFilter == CategoryMediaTypeFilter.movies && !hasMovies) {
          if (hasShows) {
            _selectedFilter = CategoryMediaTypeFilter.shows;
          } else {
            _selectedFilter = CategoryMediaTypeFilter.short;
          }
        } else if (_selectedFilter == CategoryMediaTypeFilter.shows &&
            !hasShows) {
          if (hasMovies) {
            _selectedFilter = CategoryMediaTypeFilter.movies;
          } else {
            _selectedFilter = CategoryMediaTypeFilter.short;
          }
        }
      });
    }

    await _fetchCategoryItems();
  }

  Future<void> _fetchCategoryItems() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _items = [];
      _hasReachedMax = false;
    });

    final genreId = TmdbGenreMapper.getGenreIdByName(widget.genreName) ?? 28;
    final targetType = _selectedFilter == CategoryMediaTypeFilter.shows
        ? MediaType.series
        : MediaType.movie;

    String? sortBy;
    if (_selectedFilter == CategoryMediaTypeFilter.short) {
      if (_selectedShortOption == ShortSortOption.popular) {
        sortBy = 'popularity.desc';
      } else if (_selectedShortOption == ShortSortOption.newRelease) {
        sortBy = targetType == MediaType.movie
            ? 'primary_release_date.desc'
            : 'first_air_date.desc';
      } else if (_selectedShortOption == ShortSortOption.featured) {
        sortBy = 'vote_average.desc';
      }
    }

    final List<MediaItem> rawFetched = await _apiClient.discoverByGenre(
      genreId: genreId,
      type: targetType,
      page: 1,
      sortBy: sortBy,
    );

    final fetched = MediaContentFilter.sanitize(rawFetched);

    // Resolve clearart logos for the top items to ensure hero slider only shows media with available logos
    final itemsWithLogos = await Future.wait(
      fetched.map((item) async {
        final logoPath = await _apiClient.fetchLogoPath(item.id, item.type);
        return logoPath != null ? item.copyWith(logoPath: logoPath) : item;
      }),
    );

    if (mounted) {
      setState(() {
        _items = itemsWithLogos;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _hasReachedMax) return;
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final genreId = TmdbGenreMapper.getGenreIdByName(widget.genreName) ?? 28;
    final targetType = _selectedFilter == CategoryMediaTypeFilter.shows
        ? MediaType.series
        : MediaType.movie;

    String? sortBy;
    if (_selectedFilter == CategoryMediaTypeFilter.short) {
      if (_selectedShortOption == ShortSortOption.popular) {
        sortBy = 'popularity.desc';
      } else if (_selectedShortOption == ShortSortOption.newRelease) {
        sortBy = targetType == MediaType.movie
            ? 'primary_release_date.desc'
            : 'first_air_date.desc';
      } else if (_selectedShortOption == ShortSortOption.featured) {
        sortBy = 'vote_average.desc';
      }
    }

    final newItems = await _apiClient.discoverByGenre(
      genreId: genreId,
      type: targetType,
      page: nextPage,
      sortBy: sortBy,
    );

    if (mounted) {
      setState(() {
        if (newItems.isEmpty) {
          _hasReachedMax = true;
        } else {
          _currentPage = nextPage;
          _items.addAll(newItems);
        }
        _isLoadingMore = false;
      });
    }
  }

  void _navigateToDetail(MediaItem item) {
    context.push('/detail/${item.type.name}/${item.id}', extra: item);
  }

  @override
  Widget build(BuildContext context) {
    // Show top-rated items with available clearart logo, falling back to next available items
    final itemsWithLogos = _items
        .where((item) => item.logoPath != null && item.logoPath!.isNotEmpty)
        .toList();

    // Sort logo items by voteAverage descending for top rated ordering
    itemsWithLogos.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    final List<MediaItem> heroItems = itemsWithLogos.isNotEmpty
        ? itemsWithLogos.take(5).toList()
        : _items.take(5).toList();

    return MainNavigationScaffold(
      child: AuraScaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchCategoryItems,
            color: Colors.white,
            backgroundColor: AppColors.surfaceElevated,
            strokeWidth: 2.0,
            edgeOffset: MediaQuery.of(context).padding.top + 60.0,
            displacement: 24.0,
            child: _isLoading && _items.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accentPink),
                  )
                : MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Hero Banner Slider (Latest 5 items in this category)
                        if (heroItems.isNotEmpty)
                          SliverToBoxAdapter(
                            child: BillboardHeroBanner(
                              items: heroItems,
                              autoScroll: true,
                              onPlayTap: _navigateToDetail,
                              onDetailsTap: _navigateToDetail,
                            ),
                          ),

                      // Centered Category Chips below Hero Banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_hasMovies) ...[
                                AuraCategoryPill(
                                  label: 'Movies',
                                  isSelected: _selectedFilter ==
                                      CategoryMediaTypeFilter.movies,
                                  onTap: () {
                                    if (_selectedFilter !=
                                        CategoryMediaTypeFilter.movies) {
                                      setState(() {
                                        _selectedFilter =
                                            CategoryMediaTypeFilter.movies;
                                      });
                                      _fetchCategoryItems();
                                    }
                                  },
                                ),
                                const SizedBox(width: AppTokens.spacingSm),
                              ],
                              if (_hasShows) ...[
                                AuraCategoryPill(
                                  label: 'Shows',
                                  isSelected: _selectedFilter ==
                                      CategoryMediaTypeFilter.shows,
                                  onTap: () {
                                    if (_selectedFilter !=
                                        CategoryMediaTypeFilter.shows) {
                                      setState(() {
                                        _selectedFilter =
                                            CategoryMediaTypeFilter.shows;
                                      });
                                      _fetchCategoryItems();
                                    }
                                  },
                                ),
                                const SizedBox(width: AppTokens.spacingSm),
                              ],
                              PopupMenuButton<ShortSortOption>(
                                position: PopupMenuPosition.under,
                                offset: const Offset(0, 8),
                                onSelected: (ShortSortOption option) {
                                  setState(() {
                                    _selectedFilter =
                                        CategoryMediaTypeFilter.short;
                                    _selectedShortOption = option;
                                  });
                                  _fetchCategoryItems();
                                },
                                color: AppColors.surfaceElevated
                                    .withValues(alpha: 0.95),
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  side: const BorderSide(
                                    color: AppColors.borderSubtle,
                                    width: 1,
                                  ),
                                ),
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem<ShortSortOption>(
                                    value: ShortSortOption.popular,
                                    child: Text(
                                      'Popular',
                                      style: context.auraText.bodyOverview
                                          .copyWith(
                                        color: _selectedShortOption ==
                                                    ShortSortOption.popular &&
                                                _selectedFilter ==
                                                    CategoryMediaTypeFilter
                                                        .short
                                            ? AppColors.accentPink
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<ShortSortOption>(
                                    value: ShortSortOption.newRelease,
                                    child: Text(
                                      'New',
                                      style: context.auraText.bodyOverview
                                          .copyWith(
                                        color: _selectedShortOption ==
                                                    ShortSortOption
                                                        .newRelease &&
                                                _selectedFilter ==
                                                    CategoryMediaTypeFilter
                                                        .short
                                            ? AppColors.accentPink
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<ShortSortOption>(
                                    value: ShortSortOption.featured,
                                    child: Text(
                                      'Featured',
                                      style: context.auraText.bodyOverview
                                          .copyWith(
                                        color: _selectedShortOption ==
                                                    ShortSortOption.featured &&
                                                _selectedFilter ==
                                                    CategoryMediaTypeFilter
                                                        .short
                                            ? AppColors.accentPink
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                                child: IgnorePointer(
                                  child: AuraCategoryPill(
                                    label: 'Short',
                                    isSelected: _selectedFilter ==
                                        CategoryMediaTypeFilter.short,
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Media Grid
                      if (_items.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.screenEdgeHorizontal,
                          ),
                          sliver: SliverGrid.builder(
                            itemCount: _items.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: AppTokens.posterAspectRatio,
                              mainAxisSpacing: AppTokens.spacingSm,
                              crossAxisSpacing: AppTokens.spacingSm,
                            ),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return MediaPosterCard(
                                item: item,
                                onTap: () => _navigateToDetail(item),
                              );
                            },
                          ),
                        ),

                      if (_items.isEmpty && !_isLoading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: Text(
                                'No ${widget.genreName} ${_selectedFilter == CategoryMediaTypeFilter.movies ? 'movies' : 'shows'} found.',
                                style: context.auraText.bodyOverview.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (_isLoadingMore)
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
                ),
          ),

          // Pinned Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              scrollController: _scrollController,
              forceCanPop: true,
              title: widget.genreName,
            ),
          ),
        ],
      ),
    ),
  );
  }
}
