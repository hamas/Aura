import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/media_item.dart';
import 'modals/netflix_quick_action_modal.dart';

/// Netflix-style Top 10 Numbered Shelf.
/// Features prominent metallic typography rank digits with overlay poster cards
/// and long-press quick action preview modal.
class TopTenShelf extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final void Function(MediaItem item)? onItemTap;
  final void Function(MediaItem item)? onPlayTap;

  const TopTenShelf({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final displayItems = items.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenEdgeHorizontal),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                style: context.auraText.sectionTitle
                    .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.screenEdgeHorizontal),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              final rank = index + 1;

              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: AppTokens.spacingLg),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Metallic 3D Outline Digit
                    Positioned(
                      left: -22,
                      bottom: -16,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 115,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -6,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3.5
                            ..color = const Color(0xFF6E6E73),
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Inner Fill for Digit
                    Positioned(
                      left: -22,
                      bottom: -16,
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          fontSize: 115,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -6,
                          color: Color(0xFF1E1F24),
                        ),
                      ),
                    ),

                    // Poster Card (Positioned to the right to overlap the number)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 110,
                      child: GestureDetector(
                        onLongPress: () {
                          NetflixQuickActionModal.show(
                            context: context,
                            item: item,
                            onPlayTap: onPlayTap ?? onItemTap,
                            onInfoTap: onItemTap,
                          );
                        },
                        child: AuraCard(
                          onTap: () => onItemTap?.call(item),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              item.posterPath != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.fullPosterUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          Container(color: AppColors.surfaceElevated),
                                      errorWidget: (_, __, ___) =>
                                          Container(color: AppColors.surfaceElevated),
                                    )
                                  : Container(color: AppColors.surfaceElevated),

                              // Top 10 Micro-Badge Overlay (Top-Right)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE50914), // Netflix Red Badge
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'TOP 10',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
