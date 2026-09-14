import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/media_item.dart';
import 'media_poster_card.dart';

/// Horizontally scrollable content shelf with Netflix-style typography and chevron.
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
    this.height = 230.0,
    this.itemSpacing = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 18.0),
  });

  /// Factory constructor for standard 2:3 MediaItem poster shelves
  static HorizontalContentShelf<MediaItem> media({
    Key? key,
    required String title,
    String? subtitle,
    required List<MediaItem> items,
    void Function(MediaItem item)? onItemTap,
    VoidCallback? onHeaderTap,
    double height = 230.0,
    double itemSpacing = 12.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 18.0),
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
        // Shelf Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
          child: GestureDetector(
            onTap: onHeaderTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.accentPink,
                            size: 20,
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
