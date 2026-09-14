import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/aura_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../library/domain/entities/library_item.dart';

class ContinueWatchingCard extends StatelessWidget {
  final LibraryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;
  final double width;

  const ContinueWatchingCard({
    super.key,
    required this.item,
    this.onTap,
    this.onInfoTap,
    this.width = AppTokens.continueWatchingWidth,
  });

  @override
  Widget build(BuildContext context) {
    final progress = item.progress;
    final percent = (progress?.percentage ?? 0.0).clamp(0.0, 1.0);

    final mediaUrl = item.backdropPath != null
        ? (item.backdropPath!.startsWith('http')
            ? item.backdropPath!
            : 'https://image.tmdb.org/t/p/w780${item.backdropPath}')
        : (item.posterPath != null
            ? (item.posterPath!.startsWith('http')
                ? item.posterPath!
                : 'https://image.tmdb.org/t/p/w500${item.posterPath}')
            : null);

    final height = width / AppTokens.backdropAspectRatio;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AuraCard(
            width: width,
            height: height,
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                mediaUrl != null
                    ? CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                        placeholder: (_, __) =>
                            Container(color: AppColors.surfaceElevated),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.surfaceElevated),
                      )
                    : Container(color: AppColors.surfaceElevated),
                Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 2.5,
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: const Color(0xFF333333),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentPink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacingSm),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(width: AppTokens.spacingXs),
                Expanded(
                  child: Text(
                    item.title,
                    style: context.auraText.itemTitle.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onInfoTap ?? onTap,
                  child: const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
