import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/primitives/primitives.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/media_item.dart';
import 'desktop_hover_preview_card.dart';
import 'modals/netflix_quick_action_modal.dart';

/// 2:3 Theatrical Media Poster Card built on global [AuraCard] and [AuraBadge] primitives.
/// Automatically promotes to [DesktopHoverPreviewCard] on Windows, macOS & desktop platforms.
class MediaPosterCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double width;
  final bool showRating;
  final bool showTitle;

  const MediaPosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.width = AppTokens.posterWidthMobile,
    this.showRating = true,
    this.showTitle = true,
  });

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return DesktopHoverPreviewCard(
        item: item,
        width: width,
        onTap: onTap,
        onPlayTap: onTap,
        onDetailsTap: onTap,
      );
    }

    final height = width / AppTokens.posterAspectRatio;

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onLongPress: onLongPress ??
            () {
              NetflixQuickActionModal.show(
                context: context,
                item: item,
                onPlayTap: (_) => onTap?.call(),
                onInfoTap: (_) => onTap?.call(),
              );
            },
        child: AuraCard(
          width: width,
          height: height,
          onTap: onTap,
          borderRadius: AppTokens.borderRadiusCard,
          child: ClipRRect(
            borderRadius: AppTokens.borderRadiusCard,
            child: item.posterPath != null
                ? CachedNetworkImage(
                    imageUrl: item.fullPosterUrl,
                    fit: BoxFit.cover,
                    width: width,
                    height: height,
                    memCacheWidth: (width * 2).round(),
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentPink,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: AuraIcon(
                          AppIcons.movie,
                          color: AppColors.textMuted,
                          size: 28,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: AuraIcon(
                        AppIcons.movie,
                        color: AppColors.textMuted,
                        size: 28,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
