import 'dart:ui';
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
    setState(() {
      _controller.text = query;
      _controller.selection = TextSelection.collapsed(offset: query.length);
    });
    context.read<SearchBloc>().add(SearchQueryChangedEvent(query));
    context.read<SearchBloc>().add(AddRecentSearchEvent(query));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    return PopScope(
      canPop: _controller.text.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_controller.text.isNotEmpty) {
          _controller.clear();
          _onQueryChanged('');
          setState(() {});
        }
      },
      child: AuraScaffold(
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Column(
                children: [
                  // 1. Minified Pill Search Input Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingMd,
                      vertical: AppTokens.spacingSm,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: Container(
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(100.0),
                          border: Border.all(
                            color: const Color(0x22FFFFFF),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          onChanged: (val) {
                            setState(() {});
                            _onQueryChanged(val);
                          },
                          onSubmitted: _submitQuery,
                          style: context.auraText.bodyOverview.copyWith(
                            color: Colors.white,
                            fontSize: 14.0,
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            hintText: 'Search movies, series...',
                            hintStyle: context.auraText.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 14.0,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: null,
                            suffixIcon: GestureDetector(
                              onTap: () {
                                if (_controller.text.isNotEmpty) {
                                  _controller.clear();
                                  _onQueryChanged('');
                                  setState(() {});
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 4, right: 14),
                                child: AuraIcon(
                                  _controller.text.isNotEmpty
                                      ? AppIcons.close
                                      : AppIcons.search,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuraAdaptiveAppBar(
              title: 'Search',
              opacity: 1.0,
              onBackPressed: () {
                if (_controller.text.isNotEmpty) {
                  _controller.clear();
                  _onQueryChanged('');
                  setState(() {});
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildIdleDiscoveryView(BuildContext context, SearchState state) {
    const categories = [
      'Action',
      'Adventure',
      'Animation',
      'Comedy',
      'Crime',
      'Documentary',
      'Drama',
      'Family',
      'Fantasy',
      'Horror',
      'Mystery',
      'Romance',
      'Sci-Fi',
      'Thriller',
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        // Recent Searches Section
        if (state.recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent',
                style: context.auraText.caption.copyWith(
                  fontSize: 13.0,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.read<SearchBloc>().add(ClearAllRecentSearchesEvent());
                },
                child: Text(
                  'Clear All',
                  style: context.auraText.caption.copyWith(
                    fontSize: 12.0,
                    color: AppColors.accentPink,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: state.recentSearches.map((term) {
              return _buildRecentSearchChip(context, term);
            }).toList(),
          ),
          const SizedBox(height: 28),
        ],

        // Categories Section
        Text(
          'Categories',
          style: context.auraText.caption.copyWith(
            fontSize: 13.0,
            fontWeight: FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: categories.map((genre) {
            return AuraCategoryPill(
              label: genre,
              isSelected: false,
              onTap: () {
                context.push('/category?genre=$genre');
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentSearchChip(BuildContext context, String term) {
    return GestureDetector(
      onTap: () => _submitQuery(term),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0x22FFFFFF),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  term,
                  style: context.auraText.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    context
                        .read<SearchBloc>()
                        .add(RemoveRecentSearchEvent(term));
                  },
                  child: const AuraIcon(
                    AppIcons.close,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
