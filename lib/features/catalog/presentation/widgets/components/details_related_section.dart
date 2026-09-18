import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aura/core/theme/app_tokens.dart';
import 'package:aura/features/catalog/domain/entities/media_item.dart';
import 'package:aura/features/catalog/presentation/widgets/media_poster_card.dart';

/// Horizontal scrolling carousel for Related & Recommended content.
class DetailsRelatedSection extends StatelessWidget {
  final List<MediaItem> items;

  const DetailsRelatedSection({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related & Recommended',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: AppTokens.posterWidthMobile / AppTokens.posterAspectRatio,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recItem = items[index];
              return MediaPosterCard(
                item: recItem,
                width: AppTokens.posterWidthMobile,
                showRating: true,
                showTitle: false,
                onTap: () {
                  context.push('/details/${recItem.type.name}/${recItem.id}', extra: recItem);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
