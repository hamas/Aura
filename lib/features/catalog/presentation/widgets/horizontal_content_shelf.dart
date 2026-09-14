import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_section_header.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/media_item.dart';
import 'media_poster_card.dart';

/// Horizontally scrollable content shelf built with [AuraSectionHeader] and [MediaPosterCard].
class HorizontalContentShelf<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index)? itemBuilder;
  final void Function(T item)? onItemTap;
  final VoidCallback? onHeaderTap;
  final double height;
  final double itemSpacing;
  final EdgeInsetsGeometry padding;

  const HorizontalContentShelf({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.itemBuilder,
    this.onItemTap,
    this.onHeaderTap,
    this.height = AppTokens.posterHeightMobile,
    this.itemSpacing = AppTokens.shelfCardGap,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppTokens.screenEdgeHorizontal),
  });

  /// Factory constructor for standard 2:3 MediaItem poster shelves
  static HorizontalContentShelf<MediaItem> media({
    Key? key,
    required String title,
    String? subtitle,
    required List<MediaItem> items,
    void Function(MediaItem item)? onItemTap,
    VoidCallback? onHeaderTap,
    double height = AppTokens.posterHeightMobile,
    double itemSpacing = AppTokens.shelfCardGap,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: AppTokens.screenEdgeHorizontal),
  }) {
    return HorizontalContentShelf<MediaItem>(
      key: key,
      title: title,
      subtitle: subtitle,
      items: items,
      onItemTap: onItemTap,
      onHeaderTap: onHeaderTap,
      height: height,
      itemSpacing: itemSpacing,
      padding: padding,
      itemBuilder: (context, item, index) {
        return MediaPosterCard(
          item: item,
          onTap: () {
            onItemTap?.call(item);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final ScrollPhysics scrollPhysics =
        defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS
            ? const BouncingScrollPhysics()
            : const ClampingScrollPhysics();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header Primitive
        AuraSectionHeader(
          title: title,
          subtitle: subtitle,
          onTap: onHeaderTap,
          showChevron: onHeaderTap != null,
        ),

        // Scrollable List
        SizedBox(
          height: height,
          child: ListView.separated(
            padding: padding,
            scrollDirection: Axis.horizontal,
            physics: scrollPhysics,
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: itemSpacing),
            itemBuilder: (context, index) {
              final item = items[index];
              final customBuilder = itemBuilder;
              if (customBuilder != null) {
                return customBuilder(context, item, index);
              }
              if (item is MediaItem) {
                return MediaPosterCard(
                  item: item,
                  onTap: () {
                    onItemTap?.call(item);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
