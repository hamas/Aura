import 'package:aura/core/presentation/primitives/primitives.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_icons.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/core/theme/app_typography.dart';
import 'package:aura/features/search/presentation/bloc/search_bloc.dart';
import 'package:aura/features/search/presentation/bloc/search_event.dart';
import 'package:aura/features/search/presentation/bloc/search_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AmbientSearchScreen extends StatefulWidget {
  const AmbientSearchScreen({super.key});

  @override
  State<AmbientSearchScreen> createState() => _AmbientSearchScreenState();
}

class _AmbientSearchScreenState extends State<AmbientSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    context.read<SearchBloc>().add(SearchQueryChangedEvent(query));
  }

  void _submitQuery(String query) {
    _controller.text = query;
    context.read<SearchBloc>().add(SearchQueryChangedEvent(query));
    context.read<SearchBloc>().add(AddRecentSearchEvent(query));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    return AuraScaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              children: [
                // 1. Search Input Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingMd,
                    vertical: AppTokens.spacingSm,
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    onSubmitted: _submitQuery,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search movies, series, directors...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const AuraIcon(
                        AppIcons.search,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const AuraIcon(
                                AppIcons.close,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                _controller.clear();
                                _onQueryChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // 2. Results or Idle Discovery View
                Expanded(
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, state) {
                      if (state.status == SearchStatus.loading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentPink,
                          ),
                        );
                      }

                      if (state.query.isEmpty) {
                        return _buildIdleDiscoveryView(context, state);
                      }

                      if (state.results.isEmpty) {
                        return Center(
                          child: Text(
                            'No results found for "${state.query}"',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }

                      // Active State: 3-column Poster Grid (Aspect Ratio 2/3)
                      return GridView.builder(
                        padding: const EdgeInsets.all(AppTokens.spacingMd),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: state.results.length,
                        itemBuilder: (context, index) {
                          final item = state.results[index];
                          return GestureDetector(
                            onTap: () {
                              context.read<SearchBloc>().add(
                                    AddRecentSearchEvent(item.title),
                                  );
                              context.push(
                                '/detail/${item.type.name}/${item.id}',
                                extra: item,
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: AppColors.surfaceCard,
                                child: item.posterPath != null
                                    ? CachedNetworkImage(
                                        imageUrl: item.fullPosterUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: AppColors.surfaceElevated,
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            const Center(
                                          child: AuraIcon(
                                            AppIcons.movie,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: AuraIcon(
                                          AppIcons.movie,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                              ),
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
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'Search',
              opacity: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleDiscoveryView(BuildContext context, SearchState state) {
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      physics: const BouncingScrollPhysics(),
      children: [
        // Recent Searches
        if (state.recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: context.auraText.sectionTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<SearchBloc>().add(ClearAllRecentSearchesEvent());
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.accentPink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.recentSearches.map((term) {
              return InputChip(
                label: Text(term),
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: const TextStyle(color: Colors.white),
                onPressed: () => _submitQuery(term),
                onDeleted: () {
                  context.read<SearchBloc>().add(RemoveRecentSearchEvent(term));
                },
                deleteIcon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Trending Tags Cloud
        Text(
          'Trending Topics',
          style: context.auraText.sectionTitle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.trendingTags.map((tag) {
            return ActionChip(
              label: Text('#$tag'),
              backgroundColor: AppColors.surfaceCard,
              labelStyle: const TextStyle(
                color: AppColors.accentPink,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: AppColors.accentPink.withValues(alpha: 0.3),
              ),
              onPressed: () => _submitQuery(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}
