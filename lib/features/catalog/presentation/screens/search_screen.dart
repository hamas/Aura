import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<CatalogBloc>().add(SearchQueryChangedEvent(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              children: [
                // Search Input Field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _controller,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search movies, series, anime...',
                      prefixIcon: const AuraIcon(AppIcons.search,
                          color: AppColors.textMuted),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const AuraIcon(AppIcons.close,
                                  color: AppColors.textMuted),
                              onPressed: () {
                                _controller.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // Search Results Grid
                Expanded(
                  child: BlocBuilder<CatalogBloc, CatalogState>(
                    builder: (context, state) {
                      if (state.isSearching) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentPink),
                        );
                      }

                      if (_controller.text.trim().isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AuraIcon(AppIcons.movie,
                                  size: 64, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'Discover millions of movies & shows',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state.searchResults.isEmpty) {
                        return Center(
                          child: Text(
                            'No results for "${_controller.text}"',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: state.searchResults.length,
                        itemBuilder: (context, index) {
                          final item = state.searchResults[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/detail/${item.type.name}/${item.id}',
                              extra: item,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: AppColors.surfaceCard,
                                child: item.posterPath != null
                                    ? CachedNetworkImage(
                                        imageUrl: item.fullPosterUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                            color: AppColors.surfaceElevated),
                                        errorWidget: (_, __, ___) =>
                                            const Center(
                                          child: AuraIcon(AppIcons.movie,
                                              color: AppColors.textMuted),
                                        ),
                                      )
                                    : const Center(
                                        child: AuraIcon(AppIcons.movie,
                                            color: AppColors.textMuted),
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
}
