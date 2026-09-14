import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/media_item.dart';

class TopTenShelf extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final void Function(MediaItem item)? onItemTap;

  const TopTenShelf({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final displayItems = items.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: Text(
            title,
            style: context.auraText.sectionTitle
                .copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              final rank = index + 1;

              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: AppTokens.spacingLg),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -20,
                      bottom: -15,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 100,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 3
                            ..color = const Color(0xFF555555),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 105,
                      child: AuraCard(
                        onTap: () => onItemTap?.call(item),
                        child: item.posterPath != null
                            ? CachedNetworkImage(
                                imageUrl: item.fullPosterUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AppColors.surfaceElevated),
                                errorWidget: (_, __, ___) =>
                                    Container(color: AppColors.surfaceElevated),
                              )
                            : Container(color: AppColors.surfaceElevated),
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
