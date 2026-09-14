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
  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadDiscoveryFeedsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          if (state.status == CatalogStatus.loading && state.trending.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryAccent),
            );
          }

          final heroItem = state.trending.isNotEmpty ? state.trending.first : null;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Featured Media Banner
              if (heroItem != null)
                SliverToBoxAdapter(
                  child: _buildHeroBanner(context, heroItem),
                ),

              // Trending Feed Carousel
              if (state.trending.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    title: 'Trending Today',
                    items: state.trending.skip(1).toList(),
                  ),
                ),

              // Popular Movies Carousel
              if (state.popularMovies.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    title: 'Popular Movies',
                    items: state.popularMovies,
                  ),
                ),

              // Popular Series Carousel
              if (state.popularSeries.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSection(
                    context,
                    title: 'Popular TV Series',
                    items: state.popularSeries,
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, MediaItem item) {
    final height = MediaQuery.of(context).size.height * 0.55;

    return GestureDetector(
      onTap: () => context.push('/detail/${item.type.name}/${item.id}', extra: item),
      child: Stack(
        children: [
          Container(
            height: height,
            width: double.infinity,
            foregroundDecoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC0A0D14),
                  AppTheme.background,
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
              ),
            ),
            child: item.backdropPath != null
                ? CachedNetworkImage(
                    imageUrl: item.fullBackdropUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.surface),
                    errorWidget: (_, __, ___) => Container(color: AppTheme.surface),
                  )
                : Container(color: AppTheme.surface),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.tagline != null && item.tagline!.isNotEmpty)
                  Text(
                    item.tagline!.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warningAccent.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.warningAccent, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.warningAccent, size: 13),
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
                    const SizedBox(width: 12),
                    Text(
                      item.releaseYear,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.type == MediaType.movie ? 'Movie' : 'TV Series',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/detail/${item.type.name}/${item.id}',
                    extra: item,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Watch Now'),
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
    required List<MediaItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(
          height: 220,
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
