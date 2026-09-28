import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';

/// Pinned glassmorphic header filter bar offering Netflix-style category pills
/// ("TV Shows", "Movies", "Categories ▾") with instant animated feed switching.
class StickyCategoryFilterBar extends StatelessWidget {
  final String? selectedCategory; // 'tvShows', 'movies', or specific genre name
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback? onOpenAllCategories;

  const StickyCategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.onOpenAllCategories,
  });

  final List<String> _popularGenres = const [
    'Action',
    'Anime',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Fantasy',
    'Horror',
    'K-Drama',
    'Romance',
    'Sci-Fi',
    'Thriller',
  ];

  void _showCategoriesPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F24),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.radiusLarge),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _popularGenres.map((genre) {
                    final isSelected = selectedCategory == genre;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(genre),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      selectedColor: AppColors.accentPink,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.accentPink : Colors.white12,
                        ),
                      ),
                      onSelected: (selected) {
                        Navigator.of(ctx).pop();
                        onCategorySelected(selected ? genre : null);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 1. TV Shows Pill
              _FilterPill(
                label: 'TV Shows',
                isSelected: selectedCategory == 'tvShows',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(selectedCategory == 'tvShows' ? null : 'tvShows');
                },
              ),
              const SizedBox(width: 8),

              // 2. Movies Pill
              _FilterPill(
                label: 'Movies',
                isSelected: selectedCategory == 'movies',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCategorySelected(selectedCategory == 'movies' ? null : 'movies');
                },
              ),
              const SizedBox(width: 8),

              // 3. Categories Dropdown Pill
              _FilterPill(
                label: (selectedCategory != null &&
                        selectedCategory != 'tvShows' &&
                        selectedCategory != 'movies')
                    ? selectedCategory!
                    : 'Categories ▾',
                isSelected: selectedCategory != null &&
                    selectedCategory != 'tvShows' &&
                    selectedCategory != 'movies',
                hasDropdownIcon: selectedCategory == null ||
                    selectedCategory == 'tvShows' ||
                    selectedCategory == 'movies',
                onTap: () => _showCategoriesPicker(context),
              ),

              const Spacer(),

              // Clear Filter Button (Visible when any filter is active)
              if (selectedCategory != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Clear filter',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onCategorySelected(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDropdownIcon;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    this.hasDropdownIcon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentPink
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentPink
                  : Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
